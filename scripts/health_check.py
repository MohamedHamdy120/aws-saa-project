import os
import sys
import requests

APP_URL=os.environ.get("APP_URL")
if not APP_URL:
    print("Wrong uri")
    sys.exit(1)

URL=f"{APP_URL.rstrip('/')}/health"

try:
    response=requests.get(URL,timeout=10)

except requests.exceptions.RequestException as e:
    print(f"Failed to connect: request error-{e}")
    sys.exit(1)


if response.status_code!=200:
    print(f"unexprcted code: expected 200. got {response.status_code}")
    sys.exit(1)

try:
    data=response.json()
except ValueError:
    print("invalid json format")
    sys.exit(1)

if(data["status"]=="healthy" and data["database"]=="connected"):
        print("the app is healthy")

else:
    print("unexpected body")
    sys.exit(1)

