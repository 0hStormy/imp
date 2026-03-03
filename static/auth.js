const ServerOrigin = location.origin;

async function createAccount(username, password) {
  requestData = {
    "username": username,
    "password": password
  }

  try {
    const response = await fetch(
      `${ServerOrigin}/api/createAccount`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(requestData)
      }
    );
    const codeJSON = await response.json();
    if (codeJSON.token) {
      location.replace("login.html")
    } else {
      errorPopup = document.getElementById("errorPopup");
      errorPopup.style.display = "flex";
      errorPopupSpan = document.getElementById("errorPopupSpan");
      errorPopupSpan.textContent = codeJSON.error;
    }
  } catch (error) {
    console.error('Error fetching auth code:', error);
    throw error;
  }
}

async function authenticate(username, password) {
  requestData = {
    "username": username,
    "password": password
  }

  try {
    const response = await fetch(
      `${ServerOrigin}/api/login`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(requestData)
      }
    );
    const codeJSON = await response.json();
    if (codeJSON.token) {
      localStorage.setItem("token", codeJSON.token);
      location.replace("/");
    } else {
      errorPopup = document.getElementById("errorPopup");
      errorPopup.style.display = "flex";
      errorPopupSpan = document.getElementById("errorPopupSpan");
      errorPopupSpan.textContent = codeJSON.error;
    }
  } catch (error) {
    console.error('Error fetching auth code:', error);
    throw error;
  }
}

usernameField = document.getElementById("usernameField");
passwordField = document.getElementById("passwordField");
loginSubmit = document.getElementById("loginSubmit");
signupSubmit = document.getElementById("signupSubmit");

if (loginSubmit) {
  loginSubmit.onclick = () => authenticate(
    usernameField.value,
    passwordField.value
  );
} else {
  signupSubmit.onclick = () => createAccount(
      usernameField.value,
      passwordField.value
  );
}