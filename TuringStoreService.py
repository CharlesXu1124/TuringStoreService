# dependencies imports
import requests
import json
import numpy as np
import random
import string
import datetime
import json

from flask import Flask
from flask import request

import asyncio
from aio_pika import connect, Message



# Global Variables
LATITUDE = 33.636374
LONGITUDE = -84.437215
RADIUS = 16000 # ~10mi radius in metric
NUMSITES = 100   #500

# helper function for generating random hashes
def random_string(length):
    pool = string.ascii_uppercase + string.digits
    return ''.join(random.choice(pool) for i in range(length))

def random_digits(length):
    pool = string.digits
    return ''.join(random.choice(pool) for i in range(length))

def random_string_lower_case(length):
    pool = string.ascii_lowercase + string.digits
    return ''.join(random.choice(pool) for i in range(length))


# helper function for creating a new customer
def createConsumer(email, salutation, first_name, last_name, phone_number, field_val):
    # NCR API Call
    url = "https://gateway-staging.ncrcloud.com/cdm/consumers"
    consumerAccountNumber = random_string(16)

    # construct the payload for creating customer
    curr_date = str(datetime.datetime.now())


    payload = "{\"consumerAccountNumber\":\"%s\",\"profileUsername\":\"%s\",\"salutation\":\"%s\",\"firstName\":\"%s\",\"lastName\":\"%s\",\"effectiveDate\":\"2022-01-20\",\"birthDate\":\"1983-05-15\",\"gender\":\"Bear\",\"mobile\":\"%s\",\"homeStore\":\"0123456789\",\"identifiersData\":[{\"fieldName\":\"loyaltyCard\",\"fieldValue\":\"%s\",\"status\":\"ACTIVE\",\"provider\":\"provider\"}],\"consents\":[{\"consent\":\"ANALYTICS\",\"type\":\"OPT_IN\",\"created_by\":\"NCR\",\"date\":\"%sT%s\",\"origin\":\"127.0.0.1\"}]}" % (consumerAccountNumber, email, salutation, first_name, last_name, phone_number, field_val, curr_date[0:10], curr_date[11:-1])


    headers = {
        'content-type': 'application/json',
        'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
        'nep-correlation-id': '2021-02-06'
    }

    res = requests.post(url, payload, headers=headers, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))

    print(res)
    return field_val[0:6]

# helper function for creating a new customer
def searchConsumer(email):

    url = "https://gateway-staging.ncrcloud.com/cdm/consumers/find"

    payload = "{\"searchCriteria\":{\"profileUsername\":\"%s\"},\"operator\":\"AND\",\"pageStart\":0,\"pageSize\":10}" % email

    headers = {
        'content-type': 'application/json',
        'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
        'nep-correlation-id': '2021-02-06'
    }

    res = requests.post(url, payload, headers=headers, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))

    # print(res["numberFound"])
    
    res_data = res.json()
    print(res_data["numberFound"])
    if res_data["numberFound"] == 0:
        return "not found"
    # print(data.decode("utf-8"))
    return res_data


app = Flask(__name__)

@app.route('/')
def index():
    return 'invalid call'

# @app.route('/searchByUserId', methods=['GET', 'POST'])
# def searchConsumerByUserId():
#     data = request.data
#     loaded_json = json.loads(data)
#     userId = loaded_json["userId"]
#     url = "https://gateway-staging.ncrcloud.com/cdm/consumers/find"

#     payload = "{\"searchCriteria\":{\"consumerAccountNumber\":\"%s\"},\"operator\":\"AND\",\"pageStart\":0,\"pageSize\":10}" % userId

#     headers = {
#         'content-type': 'application/json',
#         'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
#         'nep-correlation-id': '2021-02-06'
#     }

#     res = requests.post(url, payload, headers=headers, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))

#     # print(res["numberFound"])
    
#     res_data = res.json()
#     res = res_data["consumers"][0]["consumerAccountNumber"]
#     return res


@app.route('/createConsumer', methods=['GET', 'POST'])
def addCustomerToDB():
    data = request.data
    loaded_json = json.loads(data)
    email = loaded_json["email"]
    salutation = loaded_json["salutation"]
    first_name = loaded_json["first_name"]
    last_name = loaded_json["last_name"]
    phone_number = loaded_json["phone_number"]
    # randomly generate a field identifier and use the first 6 digits as the login credential
    field_val = random_digits(20)
    credential = createConsumer(email, salutation, first_name, last_name, phone_number, field_val)
    print(credential)
    return json.dumps(credential)

@app.route('/authenticateUser', methods=['GET', 'POST'])
# helper function for authenticating a registered customer
def authenticate():
    data = request.data
    loaded_json = json.loads(data)
    email = loaded_json["email"]
    password = loaded_json["password"]
    consumer = searchConsumer(email)
    if consumer == "not found":
        return json.dumps("fail")
    # print ("type of ini_object", type(consumer_data)) 
    account_num = consumer["consumers"][0]["identifiers"][0]["fieldValue"]
    print("account number %s" % account_num)
    customer_id = consumer["consumers"][0]["consumerAccountNumber"]
    addressing = consumer["consumers"][0]["salutation"] + consumer["consumers"][0]["firstName"] + " " + consumer["consumers"][0]["lastName"]
    if account_num[0:6] == password:
        return json.dumps(["pass", customer_id, addressing])
    return json.dumps("fail")

@app.route('/createOrder', methods=['GET', 'POST'])
def createOrder():

    curr_date = str(datetime.datetime.now())
    data = request.data
    loaded_json = json.loads(data)
    customer_id = loaded_json["id"]
    comments = loaded_json["comments"]

    print("order request received %s" % customer_id)

    url = 'https://gateway-staging.ncrcloud.com/order/3/orders/1'

    headers = {
        'content-type': 'application/json',
        'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
        'nep-correlation-id': '2021-02-06',

    }

    data = {
        "expireAt": "%sT%s" % (curr_date[0:10], curr_date[11:-1]),
        "comments": comments
    }

    payload = json.dumps(data)
    res = requests.post(url, payload, headers=headers, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))

    print(res.json())
    return json.dumps(res.json())

@app.route('/getOrders', methods=['GET', 'POST'])
def getOrders():
    data = request.data
    loaded_json = json.loads(data)
    customer_id = loaded_json["id"]

    print("order request received %s" % customer_id)

    url = 'https://gateway-staging.ncrcloud.com/order/3/orders/find?pageNumber=0&pageSize=10'

    headers = {
        'content-type': 'application/json',
        'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
        'nep-correlation-id': '2021-02-06'
    }

    data = {
        "customerId": customer_id
    }

    payload = json.dumps(data)
    res = requests.post(url, payload, headers=headers, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))

    print(res.json())
    return json.dumps(res.json())

# function for adding a new store on the map
@app.route('/createStore', methods=['GET', 'POST'])
def create_store():
    data = request.data
    loaded_json = json.loads(data)
    siteName = loaded_json["siteName"]
    lat = loaded_json["latitude"]
    lon = loaded_json["longitude"]
    
    url = "https://gateway-staging.ncrcloud.com/site/sites/"

    headers = {
        'content-type': 'application/json',
        'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
        'nep-correlation-id': '2021-02-06'
    }

    params = {
        "siteName": siteName,
        "coordinates": {
            "latitude": lat,
            "longitude": lon
        },
        "enterpriseUnitName": "Turing Automation %s" % siteName,
        "timeZone": "US/Eastern",
        "currency": "USD",
        'status': "ACTIVE"
    }

    payload = json.dumps(params)

    res = requests.post(url, payload, headers=headers, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))
    print(res.json())
    return json.dumps(res.json())



@app.route('/getNearbyStores', methods=['GET', 'POST'])
def get_nearby_sites():
    data = request.data
    loaded_json = json.loads(data)
    lat = loaded_json["latitude"]
    lon = loaded_json["longitude"]
    radius = loaded_json["radius"]
    numSites = loaded_json["numSites"]


    url = "https://gateway-staging.ncrcloud.com/site/sites/find-nearby/" + str(lat) + "%10," + str(lon)

    params = {"radius": radius,"numSites": numSites}  

    headers = {
        'content-type': 'application/json',
        'nep-organization': '401066af75094d12ba34fc0db38b1c0b',
        'nep-correlation-id': '2021-02-06'
    }

    response = requests.request("GET", url, headers=headers, params=params, auth=('e9246d75-d140-4167-8711-286dce27531b', 'Pwned2022'))

    # load json into lists
    response_dict = json.loads(response.text)
    
    site_dict = {}
    for i in range(0, len(response_dict['sites']) - 1):
        site_dict[response_dict['sites'][i]['id']] = [response_dict['sites'][i]['coordinates']['latitude'],
                                                      response_dict['sites'][i]['coordinates']['longitude'],
                                                      response_dict['sites'][i]['siteName']]
    return site_dict


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)