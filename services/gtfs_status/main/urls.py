from django.contrib import admin
from django.urls import path

from main.views import date_health

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/<bucket_name>/<date>/", date_health),
]
