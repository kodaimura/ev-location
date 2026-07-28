import { api } from '/js/api.js';

let LOGIN = false;
let FACILITIES = [];
let FACILITIES2 = [];
let MAP;
let GEOCODER;
let ADVANCED_MARKER_ELEMENT;
let PLACES_SERVICE;
let PLACES_SERVICE_STATUS;
let GEOMETRY;
let GOOGLE_MAP_ID = '';
let MAPS_READY = false;
let MAPS_LOAD_PROMISE;
const GEOCODE_CACHE = new Map();
const PLACES_CACHE = new Map();
const DIRECTIONS_CACHE = new Map();
let ORIGIN = { lat: 35.68139565951991, lng: 139.76711235533344 };
let ADDRESS = '';

const init = async () => {
    await getAccount();
    if (!LOGIN && !localStorage.getItem("guest_code")) {
        localStorage.setItem("guest_code", generateGuestCode())
    } else if (LOGIN && localStorage.getItem("guest_code")) {
        if (confirm("ゲストデータを引き継ぎますか？")) {
            try {
                await postHandover();
            } catch (e) {
                alert("申し訳ありません。引き継ぎに失敗しました。")
            }
        }
        localStorage.removeItem("guest_code");
    }
    getFacilities();
    getScores();

    document.getElementById("login-button").addEventListener("click", login);
    document.getElementById("account-menu-button").addEventListener("click", toggleAccountMenu);
    document.getElementById("logout-button").addEventListener("click", logout);
    document.addEventListener("click", closeAccountMenuOnOutsideClick);
    document.getElementById("evaluate-button").addEventListener("click", evaluate);
    document.getElementById("add-facility-button").addEventListener("click", addFacility);
    document.getElementById("set-original-address-button").addEventListener("click", setOriginalAddress);
    renderMapMessage("住所を設定すると地図を読み込みます。");
};

const loadGoogleMapsApi = async () => {
    if (MAPS_READY) {
        return;
    }
    if (MAPS_LOAD_PROMISE) {
        return MAPS_LOAD_PROMISE;
    }

    MAPS_LOAD_PROMISE = initializeGoogleMapsApi();
    return MAPS_LOAD_PROMISE;
};

const initializeGoogleMapsApi = async () => {
    const config = await api.get('maps/config');
    const apiKey = config?.api_key;
    GOOGLE_MAP_ID = config?.map_id || '';

    if (!apiKey) {
        throw new Error("GOOGLE_MAPS_API_KEY is not configured.");
    }

    await loadGoogleMapsScript(apiKey);
    if (GOOGLE_MAP_ID) {
        ({ AdvancedMarkerElement: ADVANCED_MARKER_ELEMENT } = await google.maps.importLibrary("marker"));
    }
    ({ PlacesService: PLACES_SERVICE, PlacesServiceStatus: PLACES_SERVICE_STATUS } = await google.maps.importLibrary("places"));
    GEOMETRY = await google.maps.importLibrary("geometry");
    GEOCODER = new google.maps.Geocoder();
    MAPS_READY = true;
};

const loadGoogleMapsScript = (apiKey) => {
    if (window.google?.maps?.importLibrary) {
        return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
        const callbackName = "__initGoogleMaps";
        window[callbackName] = () => {
            delete window[callbackName];
            resolve();
        };
        window.gm_authFailure = () => {
            reject(new Error("Google Maps authentication failed."));
        };

        const script = document.createElement("script");
        const params = new URLSearchParams({
            key: apiKey,
            v: "weekly",
            loading: "async",
            callback: callbackName,
        });
        script.src = `https://maps.googleapis.com/maps/api/js?${params.toString()}`;
        script.async = true;
        script.onerror = () => reject(new Error("Google Maps JavaScript API could not load."));
        document.head.appendChild(script);
    });
};

const renderMapMessage = (message, isError = false) => {
    const mapElement = document.getElementById('map');
    mapElement.classList.toggle('map-error', isError);
    mapElement.classList.add('map-message');
    mapElement.textContent = message;
};

const ensureMapsReady = async () => {
    if (MAPS_READY) {
        return true;
    }

    try {
        renderMapMessage("地図を読み込んでいます。");
        await loadGoogleMapsApi();
        return true;
    } catch (e) {
        console.error(e);
        renderMapMessage("Google Maps API キーが設定されていないか、Google Cloud 側の認証設定に問題があります。", true);
        alert("Google Maps API の設定を確認してください。");
        return false;
    }
};

const originCacheKey = () => {
    return `${Number(ORIGIN.lat).toFixed(6)},${Number(ORIGIN.lng).toFixed(6)}`;
};

const placesCacheKey = (facility) => {
    return `${originCacheKey()}:${facility.name.trim().toLowerCase()}`;
};

const directionsCacheKey = (place) => {
    return `${originCacheKey()}:${place.place_id || place.name}`;
};

const setOriginalAddress = async () => {
    const address = document.getElementById("address-input").value.trim();
    if (address === "") {
        alert("住所を入力してください。");
        return;
    }

    if (!await ensureMapsReady()) {
        return;
    }

    if (ADDRESS === address) {
        return;
    }

    if (GEOCODE_CACHE.has(address)) {
        ORIGIN = GEOCODE_CACHE.get(address);
        ADDRESS = address;
        resetMap();
        return;
    }

    GEOCODER.geocode({ address: address }, (results, status) => {
        if (status === "OK") {
            const location = results[0].geometry.location;
            const newOrigin = {
                lat: location.lat(),
                lng: location.lng(),
            };
            GEOCODE_CACHE.set(address, newOrigin);
            ORIGIN = newOrigin;
            ADDRESS = address;
            resetMap();
        } else {
            alert("Google Map API の無料枠の日時上限に達してしまいました。");
        }
    });
} 


const addFacility = () => {
    const facilityInput = document.querySelector(".facility-input");
    const facility = facilityInput.value;
    
    if (FACILITIES.some(d => d.name === facility)) {
        alert("施設名が重複しています。");
        return;
    }
    if (facility === "") {
        alert("施設名を入力してください。");
        return;
    }

    facilityInput.value = "";
    FACILITIES.push({"name": facility, "frequency": 1});
    postFacilities();
    renderFacility(facility, 1);
}

const renderFacility = (facility, frequency) => {
    const li = document.createElement("li");
    li.classList.add("facility-tag");
    li.classList.add(`frequency-${frequency}`);
    li.textContent = facility;
    li.onclick = () => {
        const classList = Array.from(li.classList);
        const frequencyClass = classList.find(className => /^frequency-\d+$/.test(className));
        let frequency;
        if (frequencyClass) {
            const currentNumber = parseInt(frequencyClass.split('-')[1], 10);
            frequency = currentNumber < 3 ? currentNumber + 1 : 1;
            li.classList.remove(frequencyClass);
        } else {
            frequency = 1;
        }
        li.classList.add(`frequency-${frequency}`);
        FACILITIES.forEach(item => {
            if (item.name === facility) {
                item.frequency = frequency;
            }
        });
        postFacilities();
    }

    const deleteButton = document.createElement("button");
    deleteButton.classList.add("delete-button");
    deleteButton.textContent = "×";
    deleteButton.onclick = () => {
        FACILITIES = FACILITIES.filter(d => d.name !== facility);
        postFacilities();
        li.remove();
    };
    li.appendChild(deleteButton);
    document.getElementById("facility-list").appendChild(li);
}

const evaluate = async () => {
    if (FACILITIES.length === 0) {
        alert("施設を追加してください。");
        return;
    }
    if (document.getElementById("address-input").value == "") {
        alert("物件を設定してください。");
        return;
    }
    if (document.getElementById("address-input").value != ADDRESS) {
        alert("物件を設定してください。");
        return;
    };
    if (!await ensureMapsReady()) {
        return;
    }
    await displayClosestRoutesForFacilities();
    postScore();
}

const displayClosestRoutesForFacilities = async () => {
    resetMap();
    FACILITIES2 = [];
    const displayedPlaces = new Set();
    const service = new PLACES_SERVICE(MAP);
    for (const facility of FACILITIES) {
        const results = await evaluateLocation(service, facility)
        if (results) {
            const tmp = await getClosestPlaceAndDirection(results)
            const place = tmp[0];
            const direction = tmp[1];
            if (!displayedPlaces.has(place.place_id)) {
                displayedPlaces.add(place.place_id);
                await displayPlaceDirection(place, direction);
            }
            const minuteTime = direction.routes[0].legs[0].duration.value;
            FACILITIES2.push(({"name": place.name, "frequency": facility.frequency, "time": minuteTime}));
        }
    }
}

const evaluateLocation = async (service, facility) => {
    const cacheKey = placesCacheKey(facility);
    if (PLACES_CACHE.has(cacheKey)) {
        return PLACES_CACHE.get(cacheKey);
    }

    return new Promise((resolve, reject) => {
        const request = {
            location: ORIGIN,
            radius: 500,
            query: facility.name,
        };

        service.textSearch(request, (results, status) => {
            if (status === PLACES_SERVICE_STATUS.OK && results.length > 0) {
                PLACES_CACHE.set(cacheKey, results);
                resolve(results);
            } else {
                alert("Google Map API の無料枠の日時上限に達してしまいました。");
                resolve(null);
            }
        });
    });
}

const getClosestPlaceAndDirection = async (places) => {
    const nearestPlaces = getNearestPlaces(ORIGIN, places, 2);
    if (nearestPlaces.length > 0) {
        return getClosestPlaceAndRoute(nearestPlaces);
    }
}

// 複数候補から最短ルートの場所とルートを取得する処理
const getClosestPlaceAndRoute = async (places) => {
    let min = Infinity;
    let nearestPlace;
    let nearestPlaceDirection;
    for (const place of places) {
        const cacheKey = directionsCacheKey(place);
        let response = DIRECTIONS_CACHE.get(cacheKey);
        if (!response) {
            const directionsService = new google.maps.DirectionsService();
            const directionsRequest = {
                origin: ORIGIN,
                destination: place.geometry.location,
                travelMode: google.maps.TravelMode.WALKING,
            };

            response = await new Promise((resolve, reject) => {
                directionsService.route(directionsRequest, (response, status) => {
                    if (status === google.maps.DirectionsStatus.OK) {
                        resolve(response);
                    } else {
                        alert("Google Map API の無料枠の日時上限に達してしまいました。");
                        reject(`ルートの取得に失敗しました: ${status}`);
                    }
                });
            });
            DIRECTIONS_CACHE.set(cacheKey, response);
        }

        const duration = response.routes[0].legs[0].duration.value;
        if (min > duration) {
            min = duration;
            nearestPlace = place;
            nearestPlaceDirection = response;
        }
    }
    return [nearestPlace, nearestPlaceDirection];
}

const displayPlaceDirection = async (place, placeDirection) => {
    const directionsRenderer = new google.maps.DirectionsRenderer({
        map: MAP,
        suppressMarkers: true,  // マーカーの重複を防ぐ
    });
    directionsRenderer.setDirections(placeDirection);
    createMarker({
        position: place.geometry.location,
        map: MAP,
        content: createTimeIcon(placeDirection.routes[0].legs[0].duration.text),
        label: placeDirection.routes[0].legs[0].duration.text,
    });
}

// 地図をリセットする処理
const resetMap = () => {
    const mapElement = document.getElementById('map');
    mapElement.classList.remove('map-error');
    mapElement.classList.remove('map-message');
    mapElement.textContent = '';

    const mapOptions = {
        center: ORIGIN,
        zoom: 14,
    };
    if (GOOGLE_MAP_ID) {
        mapOptions.mapId = GOOGLE_MAP_ID;
    }

    MAP = new google.maps.Map(mapElement, mapOptions);

    createMarker({
        position: ORIGIN,
        map: MAP,
    });
};

const createMarker = ({ position, map, content, label }) => {
    if (GOOGLE_MAP_ID && ADVANCED_MARKER_ELEMENT) {
        return new ADVANCED_MARKER_ELEMENT({
            position,
            map,
            content,
        });
    }

    return new google.maps.Marker({
        position,
        map,
        label: label ? {
            text: label,
            color: "#111827",
            fontWeight: "700",
        } : undefined,
    });
};

// 直線距離で近くの場所を取得する処理（ルートとしての最短の候補として）
const getNearestPlaces = (origin, results, count) => {
    return results
        .map(place => ({
            place,
            distance: GEOMETRY.spherical.computeDistanceBetween(origin, place.geometry.location)
        }))
        .sort((a, b) => a.distance - b.distance)
        .filter((item, index, self) =>
            index === self.findIndex(t => t.place.name === item.place.name)
        )
        .slice(0, count)
        .map(item => item.place);
};

// 移動時間を表示するカスタムアイコンを作成する処理
const createTimeIcon = (duration) => {
    const iconDiv = document.createElement('div');
    iconDiv.style.backgroundColor = "yellow";
    iconDiv.style.border = "2px solid black";
    iconDiv.style.borderRadius = "50%";
    iconDiv.style.padding = "8px";
    iconDiv.style.textAlign = "center";
    iconDiv.style.fontSize = "12px";
    iconDiv.style.fontWeight = "bold";
    iconDiv.style.color = "black";
    iconDiv.innerText = duration;

    return iconDiv;
};

const getFacilities = async () => {
    const url = LOGIN ? 'facilities' : `guest/${localStorage.getItem("guest_code")}/facilities`;
    try {
        const response = await api.get(url);
        if (response.facilities) {
            FACILITIES = JSON.parse(response.facilities.facilities_data);
            for (let f of FACILITIES) {
                renderFacility(f.name, f.frequency);
            }
        }
    } catch (e) {
        console.log(e)
    }
};

const postFacilities = async () => {
    const url = LOGIN ? 'facilities' : `guest/${localStorage.getItem("guest_code")}/facilities`;
    const body = {
        facilities_data: JSON.stringify(FACILITIES),
    };

    try {
        await api.post(url, body);
    } catch (e) {
        console.log(e)
    }
};

const getScores = async () => {
    const url = LOGIN ? 'scores' : `guest/${localStorage.getItem("guest_code")}/scores`
    const response = await api.get(url);
    if (response.scores) {
        const tableElement = document.querySelector("#score-table tbody:nth-of-type(2)");
        tableElement.innerHTML = "";

        for (let s of response.scores) {
            const row = document.createElement('tr');

            const addressCell = document.createElement('td');
            addressCell.textContent = s.address;
            const scoreCell = document.createElement('td');
            scoreCell.style.textAlign = 'center';
            scoreCell.textContent = s.score;

            const facilitiesCell = document.createElement('td');
            const facilitiesList = document.createElement('ul');
            facilitiesList.classList.add('facilities-list');

            for (let f of JSON.parse(s.facilities_data_2)) {
                const listItem = document.createElement('li');
                listItem.textContent = f.name;
                facilitiesList.appendChild(listItem);
            }

            facilitiesCell.appendChild(facilitiesList);

            const deleteCell = document.createElement('td');
            deleteCell.style.textAlign = 'center';
            const deleteButton = document.createElement("button");
            deleteButton.classList.add('delete-button');
            deleteButton.innerHTML = `<i class="fa-solid fa-trash"></i>`;
            deleteButton.onclick = () => {
                deleteScore(s.id.value);
            };
            deleteCell.appendChild(deleteButton);
            
            row.appendChild(addressCell);
            row.appendChild(scoreCell);
            row.appendChild(facilitiesCell);
            row.appendChild(deleteCell);

            tableElement.appendChild(row);
        }
    }
};

const postScore = async () => {
    const url = LOGIN ? 'scores' : `guest/${localStorage.getItem("guest_code")}/scores`
    const body = {
        address: ADDRESS,
        facilities_data: JSON.stringify(FACILITIES),
        facilities_data_2: JSON.stringify(FACILITIES2),
    };

    try {
        const response = await api.post(url, body);
        const tableElement = document.querySelector("#score-table tbody");
        tableElement.innerHTML = "";
        const row = document.createElement('tr');

        const addressCell = document.createElement('td');
        addressCell.textContent = ADDRESS;
        const scoreCell = document.createElement('td');
        scoreCell.style.textAlign = 'center';
        scoreCell.textContent = response.score;
        const facilitiesCell = document.createElement('td');
        const facilitiesList = document.createElement('ul');
        facilitiesList.classList.add('facilities-list');
        for (let f of FACILITIES2) {
            const listItem = document.createElement('li');
            listItem.textContent = f.name;
            facilitiesList.appendChild(listItem);
        }
        facilitiesCell.appendChild(facilitiesList);
        const deleteCell = document.createElement('td');

        row.appendChild(addressCell);
        row.appendChild(scoreCell);
        row.appendChild(facilitiesCell);
        row.appendChild(deleteCell);

        tableElement.appendChild(row);
        getScores();
    } catch (e) {
        console.log(e)
    }
};

const deleteScore = async (id) => {
    const url = LOGIN ? `scores/${id}` : `guest/${localStorage.getItem("guest_code")}/scores/${id}`
    try {
        if (confirm("削除します")) {
            await api.delete(url);
            getScores();
        }
    } catch (e) {
        console.log(e)
    }
};

const getAccount = async () => {
    try {
        const response = await api.get(`accounts/me`);
        document.getElementById("account_name").innerText = response.account_name;
        document.getElementById("login-action").hidden = true;
        document.getElementById("account-menu").hidden = false;
        LOGIN = true;
    } catch (e) {
        console.log(e)
    }
}

const postHandover = async () => {
    const body = {
        guest_code: localStorage.getItem("guest_code")
    };
    await api.post('handover', body);
}

const login = () => {
    window.location.replace("login");
}

const toggleAccountMenu = (event) => {
    event.stopPropagation();
    const menu = document.getElementById("account-menu");
    const button = document.getElementById("account-menu-button");
    const isOpen = menu.classList.toggle("is-open");
    button.setAttribute("aria-expanded", String(isOpen));
}

const closeAccountMenuOnOutsideClick = (event) => {
    const menu = document.getElementById("account-menu");
    if (menu.hidden || menu.contains(event.target)) {
        return;
    }
    menu.classList.remove("is-open");
    document.getElementById("account-menu-button").setAttribute("aria-expanded", "false");
}

const logout = async () => {
    await api.post(`logout`, {});
    api.clearAccessToken();
    window.location.reload();
}

const generateGuestCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const bytes = new Uint8Array(32);
    let result = '';
    while (result.length < 16) {
        crypto.getRandomValues(bytes);
        for (const byte of bytes) {
            if (byte >= 248) continue;
            result += chars[byte % chars.length];
            if (result.length === 16) break;
        }
    }
    return result;
}

window.load = init();
