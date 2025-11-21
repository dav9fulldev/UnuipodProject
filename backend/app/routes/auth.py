from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from ..models.database import get_db
from ..models.user import User
from pydantic import BaseModel, EmailStr
import os

router = APIRouter(prefix="/auth", tags=["authentication"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")

class UserCreate(BaseModel):
    email: EmailStr
    username: str
    phone: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class GoogleAuthRequest(BaseModel):
    id_token: str

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30)))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/register", response_model=Token)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email déjà enregistré")
    
    hashed_password = get_password_hash(user.password)
    new_user = User(
        email=user.email,
        username=user.username,
        phone=user.phone,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect"
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/google", response_model=Token)
def google_auth(request: GoogleAuthRequest, db: Session = Depends(get_db)):
    """
    Authenticate user with Google ID token
    
    This endpoint:
    1. Verifies the Google ID token
    2. Checks if user exists by google_id or email
    3. Creates new user if needed
    4. Returns JWT access token
    """
    try:
        # Import the Google auth verifier
        from ..utils.google_auth import GoogleAuthVerifier
        
        # Get Google Client ID from environment
        google_client_id = os.getenv("GOOGLE_CLIENT_ID")
        if not google_client_id:
            raise HTTPException(
                status_code=500,
                detail="Google Client ID not configured"
            )
        
        # Verify Google token
        verifier = GoogleAuthVerifier(client_id=google_client_id)
        user_info = verifier.verify_token(request.id_token)
        
        # Check if user exists by google_id
        user = db.query(User).filter(User.google_id == user_info['google_id']).first()
        
        # If not found, check by email
        if not user:
            user = db.query(User).filter(User.email == user_info['email']).first()
            
            if user:
                # Update existing user with Google info
                user.google_id = user_info['google_id']
                user.auth_provider = 'google'
                user.profile_picture = user_info['picture']
            else:
                # Create new user
                username = user_info['name'] if user_info['name'] else user_info['email'].split('@')[0]
                
                # Ensure username is unique
                base_username = username
                counter = 1
                while db.query(User).filter(User.username == username).first():
                    username = f"{base_username}_{counter}"
                    counter += 1
                
                user = User(
                    email=user_info['email'],
                    username=username,
                    google_id=user_info['google_id'],
                    profile_picture=user_info['picture'],
                    auth_provider='google',
                    hashed_password=None,  # No password for Google users
                )
                db.add(user)
        
        db.commit()
        db.refresh(user)
        
        # Generate JWT token
        access_token = create_access_token(data={"sub": user.email})
        
        return {"access_token": access_token, "token_type": "bearer"}
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Authentication failed: {str(e)}"
        )