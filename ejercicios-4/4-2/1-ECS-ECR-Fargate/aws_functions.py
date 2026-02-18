import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

def check_aws_credentials():
    try:
        session = boto3.Session()
        iam_client = session.client('iam')
        sts_client = session.client('sts')
        
        # Obtener la identidad del llamador
        identity = sts_client.get_caller_identity()
        arn = identity['Arn']
        
        if 'user' in arn:
            # Si es un usuario, obtener información del usuario
            user_name = arn.split('/')[-1]
            user = iam_client.get_user(UserName=user_name)['User']
            
            print("Credentials are working. Current user:")
            print(f"  - UserName: {user_name}")
            print(f"  - UserId: {user['UserId']}")
            print(f"  - Arn: {user['Arn']}")
            
            # Listar las políticas adjuntas al usuario
            policies = iam_client.list_attached_user_policies(UserName=user_name)['AttachedPolicies']
            print("Attached Policies:")
            for policy in policies:
                print(f"  - {policy['PolicyName']}")
            
            # Listar los grupos a los que pertenece el usuario
            groups = iam_client.list_groups_for_user(UserName=user_name)['Groups']
            print("User Groups:")
            for group in groups:
                print(f"  - {group['GroupName']}")
        
        elif 'role' in arn:
            # Si es un rol, obtener información del rol
            role_name = arn.split('/')[-1]
            print("Credentials are working. Current role:")
            print(f"  - RoleName: {role_name}")
        
        # Listar las políticas gestionadas
        managed_policies = iam_client.list_policies(Scope='AWS', OnlyAttached=True)['Policies']
        print("Predefined Managed Policies:")
        for policy in managed_policies:
            print(f"  - {policy['PolicyName']}")
        
    except NoCredentialsError:
        print("No AWS credentials found.")
    except PartialCredentialsError:
        print("Incomplete AWS credentials found.")
    except Exception as e:
        print(f"An error occurred: {e}")