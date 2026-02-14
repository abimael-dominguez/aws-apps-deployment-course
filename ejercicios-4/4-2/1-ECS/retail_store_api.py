"""
Store products API

Description:
    - Simple API to handle items using POST and GET requests.
    - Los items son productos que tienen un nombre, tag y un ID.

Run the API:
    - Sin cargar variables de entorno:
        uvicorn retail_store_api_api:app --reload
    - Cargando variables de entorno:
        uvicorn retail_store_api_api:app --reload --env-file .env

References:
    - FastAPI Tutorial: https://fastapi.tiangolo.com/tutorial/first-steps/
    - Schema Example: https://fastapi.tiangolo.com/tutorial/schema-extra-example/
"""


import os
from typing import Union
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
# import pandas as pd
from aws_functions import check_aws_credentials

# Revisar conexión a AWS
check_aws_credentials()

# Inicializar instancia de FastAPI
app = FastAPI()

# Estructura de los items que se van a recibir


class TaggedItem(BaseModel):
    name: str
    tags: Union[str, list]
    item_id: int


# Items que se reciben
my_items = {}

# Simulación de una base de datos de items en stock
my_items_in_stock = [
    {"name": "Air Jordan 1", "tags": "shoes", "item_id": 1},
    {"name": "MacBook Pro", "tags": "electronics", "item_id": 2},
    {"name": "Guitar", "tags": "music", "item_id": 3}
]

# Endpoint de bienvenida


@app.get("/")
def read_root():
    return {
        "Saludo": "Hola, ¡bienvenido al curso!"
    }


@app.post("/items/")
async def create_item(item: TaggedItem):
    """
    Recibe un item y lo guarda en el diccionario de my_items.

    Args:
        item (TaggedItem): El item que se va a guardar. Ejemplo de payload:
            {
                "name": "Air Jordan 1",
                "tags": "shoes",
                "item_id": 1
            }

    Returns:
        my_items: El item que se ha guardado.
    """
    my_items["name"] = item.name
    my_items["tags"] = item.tags
    my_items["item_id"] = item.item_id
    my_items["received"] = "OK"

    return my_items

# Estructura de los items que se van a recibir


class TaggedItem(BaseModel):
    name: str
    tags: Union[str, list]
    item_id: int


# Items que se reciben
my_items = {}

# Simulación de una base de datos de items en stock
my_items_in_stock = [
    {"name": "Air Jordan 1", "tags": "shoes", "item_id": 1},
    {"name": "MacBook Pro", "tags": "electronics", "item_id": 2},
    {"name": "Guitar", "tags": "music", "item_id": 3}
]

# Endpoint de bienvenida


@app.get("/")
def read_root():
    return {
        "Saludo": "Hola, ¡bienvenido al curso!"
    }

# Endpoint de items


@app.post("/items/")
async def create_item(item: TaggedItem):
    """
    Recibe un item y lo guarda en el diccionario de my_items.

    Args:
        item (TaggedItem): El item que se va a guardar. Ejemplo de payload:
            {
                "name": "Air Jordan 1",
                "tags": "shoes",
                "item_id": 1
            }

    Returns:
        TaggedItem: El item que se ha guardado.
    """
    my_items["name"] = item.name
    my_items["tags"] = item.tags
    my_items["item_id"] = item.item_id
    my_items["received"] = "OK"

    return my_items

# Endpoint de items en stock


@app.get("/items/{item_id}")
async def get_items(item_id: int, count: int = 1):
    """
    Busca si un ítem se encuentra en stock basado en su ID.

    Parámetros:
    - item_id (int): El ID del ítem a obtener.
    - count (int, opcional): La cantidad del ítem a obtener. Por defecto es 1.

    Retorna:
    - dict: Un diccionario con el nombre del ítem, la cantidad solicitada y si está en stock.
    - HTTPException: Si el ítem no se encuentra, retorna una excepción HTTP 404.

    Ejemplo de uso:
    - GET /items/1?count=2
    """
    item = None
    for i in my_items_in_stock:
        if i["item_id"] == item_id:
            item = i
            break

    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    # Añadir las nuevas claves al diccionario del ítem
    item_with_details = item.copy()
    item_with_details["quantity_requested"] = count
    item_with_details["in_stock"] = "True"

    return item_with_details
