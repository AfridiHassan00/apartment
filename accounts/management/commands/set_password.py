"""
Set or reset a user's password from the command line.

Usage:
    python manage.py set_password demo@example.com demo1234

This is the easiest way to create a working login for your demo:
the seed data's bcrypt hashes are unknown plaintexts, so use this
command once to set a password you actually know.
"""

from django.core.management.base import BaseCommand, CommandError
from accounts.models import User


class Command(BaseCommand):
    help = "Set a user's password (bcrypt-hashed, $2b$ prefix)."

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help="User's email address")
        parser.add_argument('password', type=str, help="New plaintext password")

    def handle(self, *args, **options):
        email = options['email'].strip().lower()
        password = options['password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise CommandError(f"No user with email {email!r} exists.")

        user.set_password(password)
        user.save(update_fields=['password'])

        self.stdout.write(self.style.SUCCESS(
            f"Password updated for {user.full_name} <{user.email}>."
        ))
        self.stdout.write(
            "You can now log in at /  with these credentials."
        )