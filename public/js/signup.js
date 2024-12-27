import { api } from '/js/api.js';

window.addEventListener("DOMContentLoaded", function() {
    document.getElementById("signup").addEventListener("click", signup);
});


const signup = async () => {
    const form = document.getElementById("signup-form");
    if (!validate(form)) return;

    const account_name = form.elements['account_name'].value;
    const account_password = form.elements['account_password'].value;

    const body = {
        account_name: account_name,
        account_password: account_password
    };

    try {
        await api.post('signup', body);
        window.location.replace('/login');
    } catch (e) {
        document.getElementById("error").innerHTML = (e.status === 409)
        ? "ユーザ名が既に使われています。"
        : "登録に失敗しました。";
    }
}

const validate = (form) => {
    const account_name = form.elements['account_name'].value;
    const account_password = form.elements['account_password'].value;
    const account_password_confirm = form.elements['account_password_confirm'].value;

    let error = "";
    if (account_name === "") {
        error = "ユーザ名を入力して下さい。";
    } else if (account_password === "") {
        error = "パスワードを入力して下さい。";
    } else if (account_password !== account_password_confirm) {
		error = "パスワードが一致していません。";
	}

    document.getElementById("error").innerHTML = error;
    return error === "";
}