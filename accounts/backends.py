"""
Custom authentication backend.

Looks up users by email (since USERNAME_FIELD = 'email') and verifies
bcrypt-hashed passwords stored in `users.password_hash`.
"""

from django.contrib.auth.backends import BaseBackend
from .models import User


class EmailBcryptBackend(BaseBackend):
    """Authenticate a user against the existing `users` table."""

    def authenticate(self, request, username=None, password=None, **kwargs):
        # Django's authenticate() passes the USERNAME_FIELD value as `username`.
        # Since USERNAME_FIELD is 'email', `username` here is the email string.
        email = (username or kwargs.get('email') or '').strip().lower()
        if not email or not password:
            return None

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Avoid leaking "user does not exist" — caller gets same None
            # whether the email is unknown or the password is wrong.
            return None

        # is_active checks account_status == 'active' (see User model)
        if not user.is_active:
            return None

        if user.check_password(password):
            return user
        return None

    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None