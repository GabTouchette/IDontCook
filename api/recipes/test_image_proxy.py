"""Tests for the cross-origin image proxy (api/api/image_proxy.py)."""
from unittest import mock

from django.test import TestCase
from django.urls import reverse


class _FakeUpstream:
    def __init__(self, status_code=200, content_type="image/jpeg", chunks=(b"abc",)):
        self.status_code = status_code
        self.headers = {"Content-Type": content_type}
        self._chunks = chunks

    def iter_content(self, chunk_size=65536):
        yield from self._chunks

    def close(self):
        pass


class ImageProxyTests(TestCase):
    def setUp(self):
        self.url = reverse("image-proxy")
        # An allowlisted, no-CORS host we proxy for.
        self.allowed = (
            "https://www.allrecipes.com/thmb/x/6650515_simple-chili.jpg"
        )

    def test_missing_url_is_bad_request(self):
        self.assertEqual(self.client.get(self.url).status_code, 400)

    def test_non_allowlisted_host_rejected(self):
        resp = self.client.get(self.url, {"url": "https://evil.example.com/x.jpg"})
        self.assertEqual(resp.status_code, 400)

    def test_non_http_scheme_rejected(self):
        resp = self.client.get(self.url, {"url": "file:///etc/passwd"})
        self.assertEqual(resp.status_code, 400)

    @mock.patch("api.image_proxy.requests.get")
    def test_allowlisted_success_adds_cors_header(self, mock_get):
        mock_get.return_value = _FakeUpstream()
        resp = self.client.get(self.url, {"url": self.allowed})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp["Access-Control-Allow-Origin"], "*")
        self.assertEqual(resp["Content-Type"], "image/jpeg")
        self.assertIn("max-age", resp["Cache-Control"])
        self.assertEqual(b"".join(resp.streaming_content), b"abc")

    @mock.patch("api.image_proxy.requests.get")
    def test_upstream_403_fails_closed(self, mock_get):
        # e.g. food.fnr.sndimg.com hotlink protection — client shows placeholder.
        mock_get.return_value = _FakeUpstream(status_code=403, content_type="text/html")
        resp = self.client.get(self.url, {"url": self.allowed})
        self.assertEqual(resp.status_code, 403)

    @mock.patch("api.image_proxy.requests.get")
    def test_non_image_content_type_rejected(self, mock_get):
        mock_get.return_value = _FakeUpstream(content_type="text/html")
        resp = self.client.get(self.url, {"url": self.allowed})
        self.assertEqual(resp.status_code, 415)
