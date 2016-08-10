# Bucky Box

## Sign Up Wizard

Here's what you need to do to use the wizard locally:

1. `RAILS_ENV=development bundle exec rake assets:precompile`
1. copy `wizard-localhost.html` to your `/public/` dir
1. `rails s`
1. goto http://buckybox.local:3000/wizard-localhost.html

And when you're done: `RAILS_ENV=development bundle exec rake assets:clean`.

_wizard-localhost.html_:

```html
<html>
<head>
<title>Test</title>
<style>
p { font-size: 100px; }
</style>
</head>

<body>
<h1>My test website!</h1>

<button onclick="_bucky_box_sign_up_wizard.push(['show']);">Show</button>

<p>blah blah blah blah blah blah...</p>
<p>blah blah blah blah blah blah...</p>

<script type="text/javascript" src="https://code.jquery.com/jquery-1.9.1.js"></script>
<script type="text/javascript" src="http://buckybox.local:3000/assets/sign_up_wizard.js" async="true"></script>
<script type="text/javascript">
  var _bucky_box_sign_up_wizard = _bucky_box_sign_up_wizard || [];
  _bucky_box_sign_up_wizard.push(["setHost", "http://buckybox.local:3000"]);
  _bucky_box_sign_up_wizard.push(["show"]);
</script>
</body>
</html>
```
