"""
Models for the accounts app.

Every model here maps to a table that already exists in
apartment_item_exchange_db (created by the .sql script). We set
`managed = False` so Django does NOT try to create, alter or drop
these tables — the schema is owned by the SQL file, not by migrations.
"""

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
import bcrypt


# ---------------------------------------------------------------------------
# Location hierarchy: Complex -> Building -> Apartment -> User
# ---------------------------------------------------------------------------
class Complex(models.Model):
    complex_id = models.AutoField(primary_key=True)
    complex_name = models.CharField(max_length=100, unique=True)
    address = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'complexes'
        managed = False

    def __str__(self):
        return self.complex_name


class Building(models.Model):
    building_id = models.AutoField(primary_key=True)
    complex = models.ForeignKey(
        Complex,
        on_delete=models.CASCADE,
        db_column='complex_id',
        related_name='buildings',
    )
    building_no = models.CharField(max_length=20)
    floor_count = models.IntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'buildings'
        managed = False
        unique_together = (('complex', 'building_no'),)

    def __str__(self):
        return f"Building {self.building_no}"


class Apartment(models.Model):
    apartment_id = models.AutoField(primary_key=True)
    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE,
        db_column='building_id',
        related_name='apartments',
    )
    unit_no = models.CharField(max_length=20)
    floor_no = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'apartments'
        managed = False
        unique_together = (('building', 'unit_no'),)

    def __str__(self):
        return self.unit_no


# ---------------------------------------------------------------------------
# User manager and model
# ---------------------------------------------------------------------------
class UserManager(BaseUserManager):
    """Minimal manager — just enough for auth lookups."""

    def get_by_natural_key(self, email):
        return self.get(email=email)


class User(AbstractBaseUser):
    """
    Maps to the `users` table in apartment_item_exchange_db.

    We inherit AbstractBaseUser (not AbstractUser) so we don't inherit
    Django's first_name/last_name/is_staff/... columns. We rewire just
    the two inherited fields we do use:
        - `password` maps to the existing `password_hash` column
        - `last_login` keeps its name (already matches the table)
    """

    VERIFICATION_CHOICES = [
        ('pending', 'Pending'),
        ('verified', 'Verified'),
        ('rejected', 'Rejected'),
    ]
    ACCOUNT_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('suspended', 'Suspended'),
    ]

    user_id = models.AutoField(primary_key=True)
    apartment = models.ForeignKey(
        Apartment,
        on_delete=models.SET_NULL,
        db_column='apartment_id',
        null=True,
        blank=True,
        related_name='residents',
    )
    full_name = models.CharField(max_length=120)
    phone = models.CharField(max_length=20, unique=True)
    email = models.CharField(max_length=120, unique=True)

    # Override AbstractBaseUser.password so the DB column is `password_hash`
    # and the max_length matches the schema (255 for bcrypt)
    password = models.CharField(max_length=255, db_column='password_hash')

    profile_photo = models.CharField(max_length=255, null=True, blank=True)
    verification_status = models.CharField(
        max_length=20, choices=VERIFICATION_CHOICES, default='pending'
    )
    account_status = models.CharField(
        max_length=20, choices=ACCOUNT_CHOICES, default='active'
    )

    # `last_login` is inherited from AbstractBaseUser as-is (column already matches)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name', 'phone']

    class Meta:
        db_table = 'users'
        managed = False

    def __str__(self):
        return f"{self.full_name} <{self.email}>"

    # -----------------------------------------------------------------------
    # Password handling: bcrypt with PHP ($2y$) compatibility
    # -----------------------------------------------------------------------
    def check_password(self, raw_password):
        """Verify a plaintext password against the stored bcrypt hash."""
        if not self.password or not raw_password:
            return False
        stored = self.password
        # Python's bcrypt library uses $2b$; PHP commonly uses $2y$.
        # The underlying algorithm is identical — just swap the prefix.
        if stored.startswith('$2y$'):
            stored = '$2b$' + stored[4:]
        try:
            return bcrypt.checkpw(
                raw_password.encode('utf-8'),
                stored.encode('utf-8'),
            )
        except (ValueError, TypeError):
            return False

    def set_password(self, raw_password):
        """Hash and store a new password using bcrypt, 12 rounds."""
        hashed = bcrypt.hashpw(
            raw_password.encode('utf-8'),
            bcrypt.gensalt(rounds=12),
        )
        self.password = hashed.decode('utf-8')

    # -----------------------------------------------------------------------
    # Properties Django's auth system expects
    # -----------------------------------------------------------------------
    @property
    def is_active(self):
        """Only 'active' accounts can log in."""
        return self.account_status == 'active'

    @property
    def is_staff(self):
        return False

    @property
    def is_superuser(self):
        return False