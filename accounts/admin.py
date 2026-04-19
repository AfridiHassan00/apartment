from django.contrib import admin

# The User model inherits from AbstractBaseUser (without PermissionsMixin),
# because the apartment_item_exchange_db schema does not carry is_staff,
# is_superuser, groups or user_permissions columns. Registering it with
# Django admin would therefore fail. Use the MySQL client, a seed script,
# or a future moderation page for user management.