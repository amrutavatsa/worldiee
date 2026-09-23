
import json

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

from api.assistant.service import AssistantService


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def assistant_view(request):
    try:
        body = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse(
            {
                "success": False,
                "error": "Invalid JSON.",
            },
            status=400,
        )

    message = body.get("message", "")
    confirmed = bool(body.get("confirmed", False))
    conversation = body.get("conversation")

    if conversation is not None and not isinstance(
        conversation,
        list,
    ):
        return JsonResponse(
            {
                "success": False,
                "error": "conversation must be a list.",
            },
            status=400,
        )

    service = AssistantService(request.user)

    result = service.handle_message(
        message=message,
        confirmed=confirmed,
        conversation=conversation,
    )

    status = 200 if result.get("success") else 400

    return JsonResponse(
        result,
        status=status,
    )
