import os
import uuid
from flask import Flask, request, redirect, session, url_for, render_template, send_file
from msal import ConfidentialClientApplication  # 変更: PublicClientApplicationからConfidentialClientApplicationへ
# from msal import PublicClientApplication  # 削除
from azure.storage.blob import BlobServiceClient
from io import BytesIO
from dotenv import load_dotenv
import logging

# ロギングの設定を追加
logging.basicConfig(level=logging.DEBUG)

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", os.urandom(24))

TENANT_ID = os.getenv("TENANT_ID")
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")  # 追加
AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
REDIRECT_PATH = "/callback"
SCOPE = ["User.Read"]
CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
CONTAINER_NAME = os.getenv("AZURE_CONTAINER_NAME")

msal_app = ConfidentialClientApplication(
    CLIENT_ID,
    authority=AUTHORITY,
    client_credential=CLIENT_SECRET  # 追加: クライアントシークレットの設定
)

def get_container_client():
    blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
    return blob_service_client.get_container_client(CONTAINER_NAME)

@app.route("/")
def index():
    logging.info("Accessing index route")
    if not session.get("user"):
        return redirect(url_for("login"))
    container_client = get_container_client()  # 変更: ヘルパー関数を使用
    blob_list = container_client.list_blobs()
    return render_template("index.html", files=[b.name for b in blob_list])

@app.route("/login")
def login():
    logging.info("Accessing login route")
    auth_url = msal_app.get_authorization_request_url(
        SCOPE, redirect_uri=request.url_root.rstrip('/') + REDIRECT_PATH
    )
    return redirect(auth_url)

@app.route(REDIRECT_PATH)
def authorized():
    logging.info("Handling authorized callback")
    if request.args.get("code"):
        try:
            result = msal_app.acquire_token_by_authorization_code(
                request.args["code"],
                scopes=SCOPE,
                redirect_uri=request.url_root.rstrip('/') + REDIRECT_PATH
            )
            logging.debug(f"Token acquisition result: {result}")  # 追加: 認証結果をログ出力
            if "id_token" in result:
                session["user"] = result.get("id_token_claims")
                logging.info("User authenticated successfully")
            else:
                logging.error("Authentication failed: No id_token in result")
        except Exception as e:
            logging.exception("Exception during token acquisition")
    else:
        logging.error("No code parameter found in request")
    return redirect(url_for("index"))

@app.route("/download")
def download():
    logging.info("Accessing download route")
    if not session.get("user"):
        return redirect(url_for("login"))
    filename = request.args.get("filename")
    if not filename:
        return redirect(url_for("index"))
    container_client = get_container_client()  # 変更: ヘルパー関数を使用
    blob_data = container_client.download_blob(filename).readall()
    return send_file(BytesIO(blob_data), as_attachment=True, download_name=filename)

@app.route("/upload", methods=["POST"])
def upload():
    logging.info("Accessing upload route")
    if not session.get("user"):
        return redirect(url_for("login"))
    file = request.files.get("file")
    if not file:
        return redirect(url_for("index"))
    container_client = get_container_client()  # 変更: ヘルパー関数を使用
    container_client.upload_blob(file.filename, file.read(), overwrite=True)
    return redirect(url_for("index"))

if __name__ == "__main__":
    logging.info("Starting the Flask app")
    app.run(debug=True)