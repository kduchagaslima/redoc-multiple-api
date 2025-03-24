import boto3
import json
import os

# Configuração do Bucket
BUCKET_NAME = os.environ.get("BUCKET_NAME")
PREFIX = os.environ.get("BUCKET_PREFIX", "")  # Pasta onde os arquivos OpenAPI estão
CLOUDFRONT_URL = os.environ.get("CLOUDFRONT_URL")
# Conectar ao S3
s3 = boto3.client("s3")

def listar_arquivos_yaml(bucket, prefix):
    """Lista os arquivos .yaml e .yml dentro do bucket/prefix especificado."""
    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    arquivos = [
        obj["Key"]
        for obj in response.get("Contents", [])
        if obj["Key"].endswith((".yaml", ".yml"))
    ]
    return arquivos

def gerar_html():
    """Gera o HTML baseado nos arquivos OpenAPI armazenados no S3."""
    arquivos = listar_arquivos_yaml(BUCKET_NAME, PREFIX)

    api_data = []
    for arquivo in arquivos:
        api_name = arquivo.split("/")[-1].replace(".yaml", "").replace(".yml", "")
        api_url = f"https://{CLOUDFRONT_URL}/{arquivo}"
        api_data.append({"name": api_name, "url": api_url})

    # Template do HTML
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>ReDoc Multi-API Sidebar</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {{
            margin: 0;
            display: flex;
            height: 100vh;
            font-family: Arial, sans-serif;
        }}
        #sidebar {{
            width: 250px;
            background-color: #0033a0;
            color: white;
            padding: 20px;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }}
        #search-box {{
            width: 100%;
            padding: 8px;
            border-radius: 5px;
            border: none;
            font-size: 14px;
            margin-bottom: 10px;
        }}
        #api_list {{
            list-style: none;
            padding: 0;
            flex-grow: 1;
        }}
        #api_list li {{
            padding: 10px;
            cursor: pointer;
            border-radius: 5px;
        }}
        #api_list li:hover {{
            background-color: #0055ff;
        }}
        #api_list li.active {{
            background-color: #ffffff;
            color: #0033a0;
            font-weight: bold;
        }}
        #main-content {{
            flex-grow: 1;
            padding: 20px;
            overflow-y: auto;
        }}
        redoc {{
            width: 100%;
            height: 100%;
        }}
    </style>
</head>
<body>

    <div id="sidebar">
        <h2>Catalogo de API's Littlecharlie Tech</h2>
        <input type="text" id="search-box" placeholder="Buscar API...">
        <ul id="api_list"></ul>
    </div>

    <div id="main-content">
        <redoc scroll-y-offset="body > nav"></redoc>
    </div>

    <script src="https://rebilly.github.io/ReDoc/releases/v1.x.x/redoc.min.js"></script>
    <script>
        var apis = {json.dumps(api_data)};

        function loadApi(url, element) {{
            Redoc.init(url);
            document.querySelectorAll("#api_list li").forEach(li => li.classList.remove("active"));
            element.classList.add("active");
        }}

        var apiList = document.getElementById("api_list");
        function renderApiList(filter = '') {{
            apiList.innerHTML = '';
            apis
                .filter(api => api.name.toLowerCase().includes(filter.toLowerCase()))
                .forEach((api, index) => {{
                    var li = document.createElement("li");
                    li.innerText = api.name;
                    li.setAttribute("data-url", api.url);
                    li.addEventListener("click", function() {{
                        loadApi(api.url, this);
                    }});
                    if (index === 0 && filter === '') {{
                        li.classList.add("active");
                        loadApi(api.url, li);
                    }}
                    apiList.appendChild(li);
                }});
        }}

        renderApiList();
        document.getElementById("search-box").addEventListener("input", function() {{
            renderApiList(this.value);
        }});
    </script>
</body>
</html>"""

    # Salvar o HTML no S3
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key="index.html",
        Body=html_content,
        ContentType="text/html"
    )

    return {"statusCode": 200, "body": "HTML atualizado no S3"}

# 🔥 Handler do Lambda (invocado pelo S3)
def lambda_handler(event, context):
    print(f"Evento recebido: {json.dumps(event)}")
    return gerar_html()
