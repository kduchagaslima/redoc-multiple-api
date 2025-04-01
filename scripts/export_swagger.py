import boto3
import json
import os

os.makedirs('/exports', exist_ok=True)

client = boto3.client('apigateway')

apis = client.get_rest_apis()

for api in apis['items']:
    api_id = api['id']
    stages = client.get_stages(restApiId=api_id)

    for stage in stages['item']:
        stage_name = stage['stageName']
        response = client.get_export(
            restApiId=api_id,
            stageName=stage_name,
            exportType='swagger',
            parameters={'extensions': 'apigateway'},
            accepts='application/json'
        )

        swagger_content = response['body'].read()
        swagger_json = json.loads(swagger_content)

        title = swagger_json.get('info', {}).get('title', 'Untitled')

        file_path = f'/exports/{title}_{api_id}_{stage_name}_swagger.json'
        with open(file_path, 'wb') as file:
            file.write(swagger_content)