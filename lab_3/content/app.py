import os
import random

ANIMALS = os.environ['ANIMALS'].split(",")

def spiritual_animal_finder():
    animals = ANIMALS
    response = {
        "animal": random.choice(animals)
    }
    return response

def lambda_handler(event, context):
    return spiritual_animal_finder()

