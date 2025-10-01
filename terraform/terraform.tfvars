
aws_region    = "us-east-1"
instance_type = "t3.micro"
ami_id        = "ami-0c02fb55956c7d316" # Amazon Linux 2 in us-west-2
# This would be better to be set in Secret Manager in AWS and import the value
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9Gqb8tDZgr88TV6il5ph3vAmtErvR04bRjI+lzQ7n6knxov+L6NEfFUHbZzvQWKXQuXhcvGLk2Guio0lhCmA7D7W23rGkFQnLHyASCRoLowx2yjvzJE/OWNSj5n9l2gK30dMv/hQrfGYuLUVABJhI8PS3tvaJb2vNEwGoPdrkWiSpuZXcHxvxlyEYeRo7oomv/ESRhilWf3SIJD1xz1UEqGwfUOqFMQ6VhsPnWRzxBS5mknyuuGmc2wV7OcAVw/EMkillUVEgczDZFH0QbDZRbHHp6VpPUrQVcY/Yp49Oq3H2m5R5xoYNlagu+yIkG1g53fF7ki88tZ+lKsjtPjuq9stI1GGL6EckLNOvDzoWX8pZVS9bFb4rzjQmrRVk0LvrqomRIBD34/KCjH7x/MtQ+cbm+1+FUDG6hJAOT0x2+2IErIYZIDzN2frjMgjX1B4Ze4NRpGON2GzdA8omMg0Q8KnKNPpLHGbbR8EmsmoTaF3AY8Qq5httTCpYMwmG+gZzSZBOzDZrH5KHOn1YHvF/+QdjQCI7+Q0q5E6zME+AQJ+yNhWuWX2/Dr6+VD+kDr7OJKarAfVfclbvVyFrdNDgs3Ve2eseQVfISErCBQyiyEgDi1xECCHrlIuEPdFRlJwDo6CdVOUlfJfSKaB9PdnjIEo0c7yQHjfqllN0/d8ZRw== melfo@melfo"
password = "Pas$w0rd"