const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { PlacesService, PlacesServiceStatus } = await google.maps.importLibrary("places");
const geometry = await google.maps.importLibrary("geometry");

let destinations = [];
let map;
let geocoder;
let origin = { lat: 35.68139565951991, lng: 139.76711235533344 };

const initMap = () => {
    geocoder = new google.maps.Geocoder();
    resetMap()

    setupDestinationAdding();
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
                    // 住所が有効な場合
                    const newOrigin = results[0].geometry.location;
                    origin = newOrigin; // グローバルoriginを更新
                    map.setCenter(newOrigin); // 地図を住所に移動
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
const setupDestinationAdding = () => {
    document.getElementById("add-destination-button").addEventListener("click", () => {
        const destinationInput = document.querySelector(".destination-input");
        const destination = destinationInput.value;
    
        if (destination) {
            destinations.push(destination);  // 入力された目的地をリストに追加
            destinationInput.value = "";  // 入力欄をクリア
    
            // 目的地リストに追加
            const li = document.createElement("li");
            li.classList.add("destination-tag"); // タグ風のクラスを追加
            li.classList.add("frequency-1");
            li.textContent = destination;
            li.onclick = () => {
                const classList = Array.from(li.classList);
                const frequencyClass = classList.find(className => /^frequency-\d+$/.test(className));
                if (frequencyClass) {
                    const currentNumber = parseInt(frequencyClass.split('-')[1], 10);
                    const nextNumber = currentNumber < 3 ? currentNumber + 1 : 1;
                    li.classList.remove(frequencyClass);
                    li.classList.add(`frequency-${nextNumber}`);
                } else {
                    li.classList.add('frequency-1');
                }
            }
    
            // 削除ボタンを作成
            const deleteButton = document.createElement("button");
            deleteButton.classList.add("delete-button"); // 削除ボタンにスタイルを適用
            deleteButton.textContent = "×";
            deleteButton.onclick = () => {
                // 削除ボタンがクリックされたときにリストから削除
                destinations = destinations.filter(d => d !== destination);
                li.remove();  // リストから目的地を削除
            };
    
            li.appendChild(deleteButton);
            document.getElementById("destination-list").appendChild(li);
        } else {
            alert("目的地を入力してください！");
        }
    });
};

// 検索ボタンの処理を別関数として分ける
const setupSearchButton = () => {
    document.getElementById("search-button").addEventListener("click", () => {
        if (destinations.length === 0) {
            return;
        }

        // 地図をリセットしてマーカーやルートを再描画
        resetMap();

        // Places APIで目的地を検索
        const service = new PlacesService(map);
        const visitedPlaces = new Set();  // すでに表示した場所を記録するためのセット
        const bounds = new google.maps.LatLngBounds();

        for (const destination of destinations) {
            const request = {
                location: origin,
                radius: 500,
                query: destination
            };

            service.textSearch(request, async (results, status) => {
                if (status === PlacesServiceStatus.OK && results.length > 0) {
                    const nearestPlaces = getNearestPlaces(origin, results, 2);

                    let nearestPlace;
                    let nearestPlaceDirection;
                    let min = Infinity;
                    for (const place of nearestPlaces) {
                        if (visitedPlaces.has(place.place_id)) {
                            return;  // すでに表示された場所はスキップ
                        }

                        visitedPlaces.add(place.place_id);

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
                    };
                    const directionsRenderer = new google.maps.DirectionsRenderer({
                        map: map,
                        suppressMarkers: true,  // マーカーの重複を防ぐ
                    });
                    directionsRenderer.setDirections(nearestPlaceDirection);
                    const marker = new AdvancedMarkerElement({
                        position: nearestPlace.geometry.location,
                        map: map,
                        content: createTimeIcon(nearestPlaceDirection.routes[0].legs[0].duration.text),
                    });
                    bounds.extend(nearestPlace.geometry.location);
                } else {
                    console.error("施設の検索に失敗しました:", status);
                }
            });
        };
        map.fitBounds(bounds);
    });
};

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

// 近くの場所を取得する処理
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

// 地図をロード
window.onload = initMap;
