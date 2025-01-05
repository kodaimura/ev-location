const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { PlacesService, PlacesServiceStatus } = await google.maps.importLibrary("places");
const geometry = await google.maps.importLibrary("geometry");

import { api } from '/js/api.js';

let facilities = [];
let facilities2 = [];
let map;
let geocoder;
let origin = { lat: 35.68139565951991, lng: 139.76711235533344 };

const initMap = async () => {
    geocoder = new google.maps.Geocoder();
    if (!localStorage.getItem("guest_code")) {
        localStorage.setItem("guest_code", generateGuestCode())
    }
    getFacilities();
    resetMap();

    setupFacilityAdding();
    setupSearchButton();
    setupAddressInput();
};

// 住所入力で地図を更新する処理
const setupAddressInput = () => {
    document.getElementById("set-origin-button").addEventListener("click", () => {
        const address = document.getElementById("address-input").value;

        if (address) {
            geocoder.geocode({ address: address }, (results, status) => {
                if (status === "OK") {
                    const newOrigin = results[0].geometry.location;
                    origin = newOrigin;
                    map.setCenter(newOrigin);
                    const originMarker = new AdvancedMarkerElement({
                        position: newOrigin,
                        map: map,
                    });
                } else {
                    alert("住所の取得に失敗しました。再試行してください。");
                }
            });
        } else {
            alert("住所を入力してください！");
        }
    });
};

// 目的地追加の処理を別関数として分ける
const setupFacilityAdding = () => {
    document.getElementById("add-facility-button").addEventListener("click", () => {
        const facilityInput = document.querySelector(".facility-input");
        const facility = facilityInput.value;
        
        if (facilities.some(d => d.name === facility)) {
            alert("施設名が重複しています");
            return;
        }

        if (facility) {
            facilityInput.value = "";
            addFacility(facility);
        } else {
            alert("施設名を入力してください");
        }
    });
};

const addFacility = (facility) => {
    facilities.push({"name": facility, "frequency": 1});
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
        facilities.forEach(item => {
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
        facilities = facilities.filter(d => d.name !== facility);
        postFacilities();
        li.remove();
    };
    li.appendChild(deleteButton);
    document.getElementById("facility-list").appendChild(li);
}

const setupSearchButton = () => {
    document.getElementById("search-button").addEventListener("click", async () => {
        if (facilities.length === 0) {
            return;
        }
        await displayClosestRoutesForFacilities();
        postScores();
    });
};

const displayClosestRoutesForFacilities = async () => {
    resetMap();
    facilities2 = [];
    const displayedPlaces = new Set();
    const service = new PlacesService(map);
    for (const facility of facilities) {
        const results = await searchFacility(service, facility)
        if (results) {
            const tmp = await getClosestPlaceAndDirection(results)
            const place = tmp[0];
            const direction = tmp[1];
            if (!displayedPlaces.has(place.place_id)) {
                displayedPlaces.add(place.place_id);
                await displayPlaceDirection(place, direction);
            }
            const minuteTime = direction.routes[0].legs[0].duration.value;
            facilities2.push(({"name": place.name, "frequency": 1, "time": minuteTime}));
        }
    }
}

const searchFacility = async (service, facility) => {
    return new Promise((resolve, reject) => {
        const request = {
            location: origin,
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
    const nearestPlaces = getNearestPlaces(origin, places, 2);
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
            origin: origin,
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
        map: map,
        suppressMarkers: true,  // マーカーの重複を防ぐ
    });
    directionsRenderer.setDirections(placeDirection);
    const marker = new AdvancedMarkerElement({
        position: place.geometry.location,
        map: map,
        content: createTimeIcon(placeDirection.routes[0].legs[0].duration.text),
    });
}

// 地図をリセットする処理
const resetMap = () => {
    map = new google.maps.Map(document.getElementById('map'), {
        center: origin,
        zoom: 14,
        mapId: "MAP_ID"
    });

    const originMarker = new AdvancedMarkerElement({
        position: origin,
        map: map,
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
    const guest_code = localStorage.getItem("guest_code");
    const response = await api.get(`/guest/${guest_code}/facilities`);
    if (response.facilities) {
        facilities = JSON.parse(response.facilities.facilities_data);
        for (let f of facilities) {
            renderFacility(f.name, f.frequency);
        }
    }
};

const postFacilities = async () => {
    const guest_code = localStorage.getItem("guest_code");
    const body = {
        facilities_data: JSON.stringify(facilities),
    };

    try {
        await api.post(`/guest/${guest_code}/facilities`, body);
    } catch (e) {
        console.log(e)
    }
};

const postScores = async () => {
    const guest_code = localStorage.getItem("guest_code");;
    const body = {
        address: document.getElementById("address-input").value,
        facilities_data: JSON.stringify(facilities),
        facilities_data_2: JSON.stringify(facilities2),
    };

    try {
        const response = await api.post(`/guest/${guest_code}/scores`, body);
    } catch (e) {
        console.log(e)
    }
};

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
