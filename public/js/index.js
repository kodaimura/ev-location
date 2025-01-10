const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { PlacesService, PlacesServiceStatus } = await google.maps.importLibrary("places");
const geometry = await google.maps.importLibrary("geometry");

import { api } from '/js/api.js';

let LOGIN = false;
let FACILITIES = [];
let FACILITIES2 = [];
let MAP;
let GEOCODER;
let ORIGIN = { lat: 35.68139565951991, lng: 139.76711235533344 };
let ADDRESS = '';

const initMap = async () => {
    GEOCODER = new google.maps.Geocoder();
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

    resetMap();
    setupFacilityAdding();
    setupEvaluateButton();
    setupAddressInput();
    
};

// 住所入力で地図を更新する処理
const setupAddressInput = () => {
    document.getElementById("set-origin-button").addEventListener("click", () => {
        const address = document.getElementById("address-input").value;

        if (address) {
            GEOCODER.geocode({ address: address }, (results, status) => {
                if (status === "OK") {
                    const newOrigin = results[0].geometry.location;
                    ORIGIN = newOrigin;
                    MAP.setCenter(newOrigin);
                    const originMarker = new AdvancedMarkerElement({
                        position: newOrigin,
                        map: MAP,
                    });
                    ADDRESS = address;
                } else {
                    alert("住所の取得に失敗しました。再試行してください。");
                }
            });
        } else {
            alert("住所を入力してください。");
        }
    });
};

// 目的地追加の処理を別関数として分ける
const setupFacilityAdding = () => {
    document.getElementById("add-facility-button").addEventListener("click", () => {
        const facilityInput = document.querySelector(".facility-input");
        const facility = facilityInput.value;
        
        if (FACILITIES.some(d => d.name === facility)) {
            alert("施設名が重複しています。");
            return;
        }

        if (facility) {
            facilityInput.value = "";
            addFacility(facility);
        } else {
            alert("施設名を入力してください。");
        }
    });
};

const addFacility = (facility) => {
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

const setupEvaluateButton = () => {
    document.getElementById("evaluate-button").addEventListener("click", async () => {
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
        await displayClosestRoutesForFacilities();
        postScore();
    });
};

const displayClosestRoutesForFacilities = async () => {
    resetMap();
    FACILITIES2 = [];
    const displayedPlaces = new Set();
    const service = new PlacesService(MAP);
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
    return new Promise((resolve, reject) => {
        const request = {
            location: ORIGIN,
            radius: 500,
            query: facility.name,
        };

        service.textSearch(request, (results, status) => {
            if (status === PlacesServiceStatus.OK && results.length > 0) {
                resolve(results);
            } else {
                console.error("施設の検索に失敗しました:", status);
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
        const directionsService = new google.maps.DirectionsService();
        const directionsRequest = {
            origin: ORIGIN,
            destination: place.geometry.location,
            travelMode: google.maps.TravelMode.WALKING,
        };

        const response = await new Promise((resolve, reject) => {
            directionsService.route(directionsRequest, (response, status) => {
                if (status === google.maps.DirectionsStatus.OK) {
                    resolve(response);
                } else {
                    reject(`ルートの取得に失敗しました: ${status}`);
                }
            });
        });

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
    const marker = new AdvancedMarkerElement({
        position: place.geometry.location,
        map: MAP,
        content: createTimeIcon(placeDirection.routes[0].legs[0].duration.text),
    });
}

// 地図をリセットする処理
const resetMap = () => {
    MAP = new google.maps.Map(document.getElementById('map'), {
        center: ORIGIN,
        zoom: 14,
        mapId: "MAP_ID"
    });

    const originMarker = new AdvancedMarkerElement({
        position: ORIGIN,
        map: MAP,
    });
};

// 直線距離で近くの場所を取得する処理（ルートとしての最短の候補として）
const getNearestPlaces = (origin, results, count) => {
    return results
        .map(place => ({
            place,
            distance: geometry.spherical.computeDistanceBetween(origin, place.geometry.location)
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
    const response = await api.get(url);
    if (response.facilities) {
        FACILITIES = JSON.parse(response.facilities.facilities_data);
        for (let f of FACILITIES) {
            renderFacility(f.name, f.frequency);
        }
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
            const deleteButton = document.createElement("button");
            deleteButton.textContent = "削除";
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

const generateGuestCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < 11; i++) {
        const randomIndex = Math.floor(Math.random() * chars.length);
        result += chars[randomIndex];
    }
    return result;
}

// 地図をロード
window.onload = initMap;
