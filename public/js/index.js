const { Map, LatLngBounds } = await google.maps.importLibrary("maps");
const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");
const { PlacesService, PlacesServiceStatus } = await google.maps.importLibrary("places");
const geometry = await google.maps.importLibrary("geometry");

function initMap() {
    //const origin = { lat: 35.68139565951991, lng: 139.76711235533344 };
    const origin = { lat: 35.693815233679494, lng: 139.80926756129662 };

    const map = new Map(document.getElementById('map'), {
        center: origin,
        zoom: 14,
        mapId: "DEMO_MAP_ID"
    });

    // 出発地点のマーカーを追加
    const originMarker = new AdvancedMarkerElement({
        position: origin,
        map: map,
    });

    // Places APIを使って最寄りのジムを検索
    const service = new PlacesService(map);
    const request = {
        location: origin,
        radius: 1000, // 5km以内の範囲を検索
        //type: 'train_station', // 施設の種類を指定
        query: 'エニタイムフィットネス',
    };

    service.textSearch(request, function (results, status) {
        if (status === PlacesServiceStatus.OK && results.length > 0) {
            const nearestPlaces = getNearestPlaces(origin, results, 2);

            const bounds = new google.maps.LatLngBounds();
            nearestPlaces.forEach((place, index) => {
                const pinTextGlyph = new PinElement({
                    background: "yellow",
                    borderColor: "black",
                    glyph: (index + 1).toString(), // 番号を表示
                    glyphColor: "black",
                });
                new AdvancedMarkerElement({
                    position: place.geometry.location,
                    map: map,
                    content: pinTextGlyph.element,
                });
                bounds.extend(place.geometry.location);

                // ルートを描画
                const directionsService = new google.maps.DirectionsService();
                const directionsRenderer = new google.maps.DirectionsRenderer({
                    map: map,
                    suppressMarkers: true, // マーカーを重複しないように suppress
                });

                const request = {
                    origin: origin,
                    destination: place.geometry.location,
                    travelMode: google.maps.TravelMode.WALKING, // 徒歩のルート
                };

                directionsService.route(request, function (response, status) {
                    if (status === google.maps.DirectionsStatus.OK) {
                        directionsRenderer.setDirections(response);

                        // 移動時間をコンソールに表示
                        const route = response.routes[0];
                        const duration = route.legs[0].duration.text;
                        console.log(`移動時間 (${index + 1}番目のジム): ${duration}`);
                    } else {
                        console.error('ルートの取得に失敗しました:', status);
                    }
                });
            });
            bounds.extend(origin);
            map.fitBounds(bounds);
        } else {
            console.error("施設の検索に失敗しました:", status);
        }
    });

    function getNearestPlaces(origin, results, count) {
        // 距離を計算してソート
        const placesWithDistance = results.map(place => {
            const distance = geometry.spherical.computeDistanceBetween(
                origin,
                place.geometry.location
            );
            return { place, distance };
        });

        // 距離の昇順でソート
        placesWithDistance.sort((a, b) => a.distance - b.distance);

        // 上位N件を取得
        return placesWithDistance.slice(0, count).map(item => item.place);
    }
}

// 地図をロード
window.onload = initMap;