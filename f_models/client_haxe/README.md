# Models

Plan:
1. Extract models from components to contain game state.
2. Save state in local SharedObject. Now, you can continue, where you ended last time.
3. Save state in HTTP server. Now, all app users share same game state.
    Use Service classes inside models.
4. Use socket server. Now, all app users change same game state online. All play one game.
    Use Protocol classes in models and components.
5. Run from social network (for login). 
    If use HTTP server, you have got your save on different machines.
    If use socket server, you know whom you are playing with.


todo upload http server on some free hosting (e.g. heroku) and test app on different devices
