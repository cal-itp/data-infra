import urllib.parse


def url_split(url):
    # For analyzing urls we usually only want the domain and the path+query
    url_obj = urllib.parse.urlparse(url)
    if url_obj.query:
        return url_obj.netloc, f"{url_obj.path}?{url_obj.query}"
    return url_obj.netloc, url_obj.path
