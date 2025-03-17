# powershell-graph-api-auth-onbehalf-of-users
PowerShell example for authenticating on behalf of a user.


Before you begin using this script, you'll need to create an app registration.
I will not detail the full breakdown of creating an app registration as it's extensively covered by various sources. I will however confirm the sections of configuration needed to make this work.

Redirect for single page application:
![Example](https://github.com/user-attachments/assets/af9c0c4c-c8e8-4fea-984f-e5abb1fe935d)
In the highlighted section add:
`http://localhost:5000`
Apply Delegated API permissions to the application for the required operations you need:

<img width="513" alt="Permissions" src="https://github.com/user-attachments/assets/afd045e9-9137-4636-8c90-20edea71761a" />

Finally grant your user account access to the application registration & run the script.

If not signed in, you will be asked for your credentials. If successful you will be told to close the browser.
In your powershell window you will be greeted with a Graph API call displaying the user signed in.

You can now make calls to the Graph API as your signed in user.
