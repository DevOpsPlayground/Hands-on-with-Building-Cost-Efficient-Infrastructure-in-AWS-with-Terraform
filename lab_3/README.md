# Implementing database
## User story

Hello DevOps team, thank you for saving us last time! I am afraid we will need your help again. Service is great and it is all what we were wishing for, but some of our customers are suggesting that it is not credible as you are getting different animal for the same names - can we do something about it?


## Approach
We have yet another challenge to solve, we need to make sure that same user will not get the different animal each time they try to use our service. We need to add some persistent storage to our design to do so and we will use a DynamoDB, a NoSQL database which we can eaisly integrate with our current desing. All we need to do is to create the table which will store the users with their assigned animals and modify our lambda function too check for "already predicted"  users first and return the previous assingment. We can use the code from our previos labs to start with.
## Lets do it
### Step one: Create a database table
Configuration from the previous lab is already in `main.tf`, just add your panda to `variables.tf` and make sure you ran `terraform destroy` on previous workspace (lab_2)
```go
variable "my_panda" {
  default     = "YOUR-PANDA"
  description = "The name of your panda (provided with environment) i.e. happy-panda"
}
```
Our first step will be to create a database table where we will store our users, we will need to add the following to our `main.tf`
```golang
resource "aws_dynamodb_table" "users" {
  name             = "playground-${var.my_panda}"
  hash_key         = "users"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = false
  attribute {
    name = "users"
    type = "S"
  }
  tags = {
    Owner = "playground-${var.my_panda}"
  }
}
```
Next we need to make sure that our Lambda function has sufficient permissions so we will create appropriate policy.
```golang
resource "aws_iam_policy" "dynamodb" {
  name        = "playground-${var.my_panda}"
  path        = "/"
  description = "DynamoDB policy for lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:*",
        ]
        Effect   = "Allow"
        Resource = "${aws_dynamodb_table.users.arn}"
      },
    ]
  })
}
```
And attach it to the role
```go
resource "aws_iam_policy_attachment" "lambda" {
  name = "dynamodb-to-lambda"
  roles = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.dynamodb.arn
}
​​​​​​​
```
Once we ensure that our function can talk to our database, now we need to modify our function to do so, we need to check if users with the certain name already tried to use our service and if so we want them to get the same animal. We also need to save the users with unique names. We will use boto3 and a few lines below should do it. Please replace `YOUR-PANDA` with the value from your variables
```python
import os
import random
import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb", region_name='eu-west-2')

ANIMALS = os.environ['ANIMALS'].split(",")

def spiritual_animal_finder(event):
    response = {
        "animal": check_user(event)
    }
    return response
    
def check_user(event):
    if "name" in event:
        user = event["name"]
    else:
        return "Bad request, no user key in the payload"    
    users = dynamodb.Table('playground-YOUR-PANDA')
    try:
        response = users.get_item(
            Key={
                'users': user
            }
        )
        print("user", response)
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        if 'Item' in response:
            return response['Item']['animals']
        else:
            animal = random.choice(ANIMALS)
            add_user(user, animal)
            return animal
            
def add_user(user,animal):
    table = dynamodb.Table('playground-YOUR-PANDA')
    table.update_item(
        Key={
        'users': user
        
    },
    UpdateExpression="set animals = :c",
    ExpressionAttributeValues={
        ':c': animal
    },
    ReturnValues="UPDATED_NEW"
    )
    print("PutItem succeeded:")
    
def lambda_handler(event, context):
    return spiritual_animal_finder(event)

```

Once we saved our files it is time to hit 
```
terraform init
``` 
and
```
terraform apply
``` 
for the last time and se our app in action! Our service should work as required now! 

That is all  we had for you today, once your app is tested don't forget to run 
```
terraform destroy
```