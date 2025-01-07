const BASE_URL = '/api';


class HttpError extends Error {
    status;
    details;

    constructor(status, message, details) {
        super(message);
        this.status = status;
        this.details = details;
    }
}

class Api {
    #url;

    constructor(url) {
        this.#url = url;
    }

    apiFetch = async (endpoint, method, body) => {
        if (endpoint.startsWith('/')) {
            endpoint = endpoint.slice(1);
        }
        try {
            let header = {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                },
            };
    
            if (body) {
                header.body = JSON.stringify(body);
            }
            const response = await fetch(`${this.#url}/${endpoint}`, header);
    
            if (!response.ok) {
                const errorData = await response.json();
                throw new HttpError(response.status, errorData.error, errorData.details);
            }
    
            let data;
            try {
                data = await response.json();
            } catch (error) {
                if (response.status !== 204 && response.status !== 200) {
                    throw new HttpError(response.status, 'Error parsing JSON', {});
                }
            }
            return data;
        } catch (error) {
            if (error instanceof HttpError) {
                this.handleHttpError(error);
            } else {
                console.error(error);
                throw error;
            }
        }
    };

    get = async (endpoint) => {
        return this.apiFetch(endpoint, 'GET', null);
    };
    
    post = async (endpoint, body) => {
        return this.apiFetch(endpoint, 'POST', body);
    };
    
    put = async (endpoint, body) => {
        return this.apiFetch(endpoint, 'PUT', body);
    };
    
    delete = async (endpoint, body) => {
        return this.apiFetch(endpoint, 'DELETE', body);
    };

    handleHttpError = (error) => {
        console.error(error);
        throw error;
    };
}

const api = new Api(BASE_URL);
api.handleHttpError = (error) => {
    const status = error.status;
    if (status === 401) {
        if (window.location.pathname !== '/login') {
            //window.location.replace('/login');
        }
    } else if (status === 403) {
        alert("権限がありません。");
    } else if (status === 500) {
        alert("予期せぬエラーが発生しました。");
    }
    throw error;
}

export { HttpError, Api, BASE_URL, api };