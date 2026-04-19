from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.views.decorators.http import require_http_methods


@require_http_methods(["GET", "POST"])
def login_view(request):
    # If already signed in, skip straight to the dashboard
    if request.user.is_authenticated:
        return redirect('dashboard')

    error = ""
    email_value = ""

    if request.method == "POST":
        email = request.POST.get("email", "").strip().lower()
        password = request.POST.get("password", "")
        email_value = email  # keep the typed email in the form on failure

        if not email or not password:
            error = "Please enter both email and password."
        else:
            # authenticate() calls our EmailBcryptBackend
            user = authenticate(request, username=email, password=password)
            if user is not None:
                login(request, user)
                messages.success(
                    request, f"Welcome back, {user.full_name}!"
                )
                next_url = (
                    request.POST.get('next')
                    or request.GET.get('next')
                    or 'dashboard'
                )
                return redirect(next_url)
            else:
                error = "Invalid email or password, or your account is not active."

    return render(request, "login.html", {
        "error": error,
        "email_value": email_value,
        "next": request.GET.get('next', ''),
    })


@login_required(login_url='login')
def dashboard_view(request):
    """Show a summary of the logged-in user plus their residence."""
    user = request.user

    apartment = None
    building = None
    complex_obj = None

    # `apartment_id` is the FK column on the user; guard against NULL
    if user.apartment_id:
        try:
            apartment = user.apartment
            building = apartment.building
            complex_obj = building.complex
        except Exception:
            # If the FK chain is broken for any reason, just show nothing
            apartment = building = complex_obj = None

    return render(request, "dashboard.html", {
        "user": user,
        "apartment": apartment,
        "building": building,
        "complex_obj": complex_obj,
    })


def logout_view(request):
    if request.user.is_authenticated:
        name = request.user.full_name
        logout(request)
        messages.info(request, f"Goodbye, {name}. You have been logged out.")
    return redirect("login")