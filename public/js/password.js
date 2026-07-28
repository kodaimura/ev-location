import { api } from '/js/api.js';

window.addEventListener("DOMContentLoaded", async function() {
    try {
        await api.get('accounts/me');
    } catch (e) {
        window.location.replace('/login');
        return;
    }

    document.getElementById("change-password").addEventListener("click", changePassword);
});

const changePassword = async () => {
    const form = document.getElementById("password-form");
    const current_password = form.elements['current_password'].value;
    const new_password = form.elements['new_password'].value;
    const new_password_confirm = form.elements['new_password_confirm'].value;
    const errorElement = document.getElementById("error");
    const successElement = document.getElementById("success");

    errorElement.textContent = "";
    successElement.textContent = "";

    const error = validate(current_password, new_password, new_password_confirm);
    if (error) {
        errorElement.textContent = error;
        return;
    }

    try {
        await api.post('password', {
            current_password,
            new_password,
        });
        api.clearAccessToken();
        alert("パスワードを変更しました。再度ログインしてください。");
        window.location.replace('/login');
    } catch (e) {
        errorElement.textContent = (e.status === 401)
            ? "現在のパスワードが異なります。"
            : "パスワード変更に失敗しました。";
    }
};

const validate = (currentPassword, newPassword, newPasswordConfirm) => {
    if (currentPassword === "") {
        return "現在のパスワードを入力してください。";
    }
    if (newPassword === "") {
        return "新しいパスワードを入力してください。";
    }
    if (newPassword !== newPasswordConfirm) {
        return "新しいパスワードが一致していません。";
    }
    if (currentPassword === newPassword) {
        return "現在と異なるパスワードを入力してください。";
    }
    return "";
};
