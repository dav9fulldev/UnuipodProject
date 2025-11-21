"""Google Authentication Utility

This module provides functionality to verify Google ID tokens
"""

from google.auth.transport import requests
from google.oauth2 import id_token
from typing import Dict, Optional


class GoogleAuthVerifier:
    """Verifies Google ID tokens and extracts user information"""
    
    def __init__(self, client_id: str):
        """
        Initialize the Google Auth Verifier
        
        Args:
            client_id: Google OAuth 2.0 client ID
        """
        self.client_id = client_id
    
    def verify_token(self, token: str) -> Dict[str, str]:
        """
        Verify Google ID token and return user information
        
        Args:
            token: Google ID token to verify
            
        Returns:
            Dictionary containing user information:
                - email: User's email address
                - name: User's full name
                - picture: URL to profile picture
                - google_id: Google user ID (sub claim)
                
        Raises:
            ValueError: If token is invalid or verification fails
        """
        try:
            # Verify the token
            idinfo = id_token.verify_oauth2_token(
                token, 
                requests.Request(), 
                self.client_id
            )
            
            # Verify token is for our application
            if idinfo['aud'] != self.client_id:
                raise ValueError('Token audience mismatch')
            
            # Extract user information
            return {
                'email': idinfo['email'],
                'name': idinfo.get('name', ''),
                'picture': idinfo.get('picture', ''),
                'google_id': idinfo['sub']
            }
        except ValueError as e:
            raise ValueError(f'Invalid Google token: {str(e)}')
        except Exception as e:
            raise ValueError(f'Token verification failed: {str(e)}')
