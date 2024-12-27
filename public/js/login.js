import { api } from '/js/api.js';

window.addEventListener("DOMContentLoaded", function() {
    document.getElementById("login").addEventListener("click", login);
});


const login = async () => {
    const form = document.getElementById("login-form");
    const account_name = form.elements['account_name'].value;
    const account_password = form.elements['account_password'].value;

    const body = {
        account_name: account_name,
        account_password: account_password
    };

    try {
        await api.post('login', body);
        window.location.replace('/');
    } catch (e) {
        document.getElementById("error").innerHTML = (e.status === 401)
        ? "ユーザ名またはパスワードが異なります。" 
        : "ログインに失敗しました。";
    }
}