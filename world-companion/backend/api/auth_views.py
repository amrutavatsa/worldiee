import json

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.http import JsonResponse

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token


@api_view(["POST"])
@permission_classes([AllowAny])
def register_view(request):
    try:
        username = request.data["username"]
        password = request.data["password"]
    except KeyError:
        return JsonResponse(
            {
                "error": 'expected JSON body: {"username": "...", "password": "..."}'
            },
            status=400,
        )

    if not username.strip() or not password:
        return JsonResponse(
            {"error": "username and password are required"},
            status=400,
        )

    if len(password) < 8:
        return JsonResponse(
            {"error": "password must be at least 8 characters"},
            status=400,
        )

    if User.objects.filter(username=username).exists():
        return JsonResponse(
            {"error": "username already exists"},
            status=409,
        )

    user = User.objects.create_user(
        username=username,
        password=password,
    )

    token, _ = Token.objects.get_or_create(user=user)

    return JsonResponse(
        {
            "success": True,
            "data": {
                "token": token.key,
                "user": {
                    "id": user.id,
                    "username": user.username,
                },
            },
        },
        status=201,
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def login_view(request):
    try:
        username = request.data["username"]
        password = request.data["password"]
    except KeyError:
        return JsonResponse(
            {
                "error": 'expected JSON body: {"username": "...", "password": "..."}'
            },
            status=400,
        )

    user = authenticate(
        username=username,
        password=password,
    )

    if user is None:
        return JsonResponse(
            {"error": "invalid username or password"},
            status=401,
        )

    token, _ = Token.objects.get_or_create(user=user)

    return JsonResponse(
        {
            "success": True,
            "data": {
                "token": token.key,
                "user": {
                    "id": user.id,
                    "username": user.username,
                },
            },
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def profile_view(request):
    return JsonResponse(
        {
            "success": True,
            "data": {
                "id": request.user.id,
                "username": request.user.username,
            },
        }
    )