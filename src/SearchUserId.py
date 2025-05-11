import requests

def get_user_id_from_username(username: str) -> int:
    url = "https://users.roblox.com/v1/usernames/users"
    data = {
        "usernames": [username],
        "excludeBannedUsers": False
    }
    r = requests.post(url, json=data)
    r.raise_for_status()
    response_data = r.json()

    if response_data["data"]:
        return response_data["data"][0]["id"]
    else:
        raise ValueError(f"Username '{username}' not found")

# Example usage:
user_id = get_user_id_from_username("CatSloth2011")
print(user_id)  # Prints player's User ID