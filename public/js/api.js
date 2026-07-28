const BASE_URL = '/api';
const AUTH_RETRY_EXCLUDED_ENDPOINTS = new Set(['login', 'signup', 'refresh', 'logout']);

let accessToken = null;
let refreshPromise = null;

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

    apiFetch = async (endpoint, method, body, retryOnUnauthorized = true) => {
        if (endpoint.startsWith('/')) {
            endpoint = endpoint.slice(1);
        }
        try {
            let header = {
                method: method,
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/json',
                },
            };
            if (accessToken) {
                header.headers.Authorization = `Bearer ${accessToken}`;
            }
    
            if (body) {
                header.body = JSON.stringify(body);
            }
            const response = await fetch(`${this.#url}/${endpoint}`, header);
    
            if (!response.ok) {
                if (
                    response.status === 401 &&
                    retryOnUnauthorized &&
                    !AUTH_RETRY_EXCLUDED_ENDPOINTS.has(endpoint)
                ) {
                    const refreshed = await this.refreshAccessToken();
                    if (refreshed) {
                        return this.apiFetch(endpoint, method, body, false);
                    }
                }

                let errorData = {};
                try {
                    errorData = await response.json();
                } catch (error) {
                    errorData = {};
                }
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
            if (data?.access_token) {
                this.setAccessToken(data.access_token);
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

    refreshAccessToken = async () => {
        if (refreshPromise) {
            return refreshPromise;
        }

        refreshPromise = fetch(`${this.#url}/refresh`, {
            method: 'POST',
            credentials: 'same-origin',
            headers: {
                'Content-Type': 'application/json',
            },
            body: '{}',
        })
            .then(async (response) => {
                if (!response.ok) {
                    this.clearAccessToken();
                    return false;
                }
                const data = await response.json();
                if (!data?.access_token) {
                    this.clearAccessToken();
                    return false;
                }
                this.setAccessToken(data.access_token);
                return true;
            })
            .catch((error) => {
                console.error(error);
                this.clearAccessToken();
                return false;
            })
            .finally(() => {
                refreshPromise = null;
            });

        return refreshPromise;
    };

    setAccessToken = (token) => {
        accessToken = token;
    };

    clearAccessToken = () => {
        accessToken = null;
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
