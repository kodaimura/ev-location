const { Map } = await google.maps.importLibrary("maps");
const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
const { PlacesService, PlacesServiceStatus } = await google.maps.importLibrary("places");
const geometry = await google.maps.importLibrary("geometry");

function initMap() {
    const origin = { lat: 35.693815233679494, lng: 139.80926756129662 };  // 例: 錦糸町駅の位置

    const map = new Map(document.getElementById('map'), {
        center: origin,
        zoom: 14,
        mapId: "DEMO_MAP_ID"
    });

    const originMarker = new AdvancedMarkerElement({
        position: origin,
        map: map,
    });

    // 「検索」ボタンがクリックされたときのイベントを設定
    document.getElementById("search-button").addEventListener("click", function() {
        const destination = document.getElementById("destination-input").value;

        if (!destination) {
            alert("目的地を入力してください！");
            return;
        }

        // Places APIで目的地を検索
        const service = new PlacesService(map);
        const request = {
            location: origin,
            radius: 900,
            query: destination
        };

        const visitedPlaces = new Set();  // すでに表示した場所を記録するためのセット

        service.textSearch(request, function (results, status) {
            if (status === PlacesServiceStatus.OK && results.length > 0) {
                const nearestPlaces = getNearestPlaces(origin, results, 2);

                const bounds = new google.maps.LatLngBounds();
                nearestPlaces.forEach((place, index) => {
                    if (visitedPlaces.has(place.place_id)) {
                        return;  // すでに表示された場所はスキップ
                    }

                    visitedPlaces.add(place.place_id);

                    const directionsService = new google.maps.DirectionsService();
                    const directionsRenderer = new google.maps.DirectionsRenderer({
                        map: map,
                        suppressMarkers: true,  // マーカーの重複を防ぐ
                    });

                    const request = {
                        origin: origin,
                        destination: place.geometry.location,
                        travelMode: google.maps.TravelMode.WALKING,  // 徒歩のルート
                    };

                    directionsService.route(request, function (response, status) {
                        if (status === google.maps.DirectionsStatus.OK) {
                            directionsRenderer.setDirections(response);

                            // 移動時間を取得
                            const route = response.routes[0];
                            const duration = route.legs[0].duration.text;

                            // 移動時間を表示するカスタムアイコンを作成
                            const marker = new AdvancedMarkerElement({
                                position: place.geometry.location,
                                map: map,
                                content: createTimeIcon(duration),  // アイコンに移動時間を表示
                            });
                        } else {
                            console.error('ルートの取得に失敗しました:', status);
                        }
                    });

                    bounds.extend(place.geometry.location);
                });
                bounds.extend(origin);
                map.fitBounds(bounds);
            } else {
                console.error("施設の検索に失敗しました:", status);
            }
        });
    });

    function getNearestPlaces(origin, results, count) {
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
    }

    function createTimeIcon(duration) {
        // 移動時間を表示するカスタムアイコン（テキスト）を作成
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
    }
}

// 地図をロード
window.onload = initMap;
