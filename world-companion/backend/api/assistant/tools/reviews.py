from api.models import Review


def get_reviews(target_type, target_id):
    reviews = Review.objects.filter(
        target_type=target_type,
        target_id=target_id,
    )

    count = reviews.count()

    average_rating = (
        sum(review.rating for review in reviews) / count
        if count
        else None
    )

    data = [
        {
            "author": review.author_name,
            "rating": review.rating,
            "comment": review.comment,
            "created_at": review.created_at.isoformat(),
        }
        for review in reviews
    ]

    return {
        "average_rating": average_rating,
        "count": count,
        "reviews": data,
    }
