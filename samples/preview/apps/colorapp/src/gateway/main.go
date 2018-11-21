package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/pkg/errors"
)

const defaultPort = "8080"

var stats map[string]int

func getServerPort() string {
	port := os.Getenv("SERVER_PORT")
	if port != "" {
		return port
	}

	return defaultPort
}

func getColorTellerEndpoint() (string, error) {
	colorTellerEndpoint := os.Getenv("COLOR_TELLER_ENDPOINT")
	if colorTellerEndpoint == "" {
		return "", errors.New("COLOR_TELLER_ENDPOINT is not set")
	}
	return colorTellerEndpoint, nil
}

func getColorHandler(writer http.ResponseWriter, request *http.Request) {
	color := getColorFromColorTeller()
	statsJson, err := json.Marshal(stats)
	if err != nil {
		fmt.Fprintf(writer, `{"color":"%s", "error":"%s"}`, color, err)
		return
	}
	fmt.Fprintf(writer, `{"color":"%s", "stats": %s}`, color, statsJson)
}

func clearColorStatsHandler(writer http.ResponseWriter, request *http.Request) {
	stats = make(map[string]int)
	fmt.Fprint(writer, "cleared")
}

func getColorFromColorTeller() string {
	colorTellerEndpoint, err := getColorTellerEndpoint()
	if err != nil {
		return fmt.Sprintf("Sorry, unexpected error %s", err)
	}

	resp, err := http.Get(fmt.Sprintf("http://%s", colorTellerEndpoint))
	if err != nil {
		return fmt.Sprintf("Sorry, %s returned error", colorTellerEndpoint)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return fmt.Sprintf("Sorry, unexpected error")
	}

	color := string(body)
	stats[color] = stats[color] + 1
	return color
}

func main() {
	log.Println("starting server, listening on port " + getServerPort())
	stats = make(map[string]int)
	colorTellerEndpoint, err := getColorTellerEndpoint()
	if err != nil {
		log.Fatalln(err)
	}
	log.Println("using color-teller at " + colorTellerEndpoint)
	http.HandleFunc("/color", getColorHandler)
	http.HandleFunc("/color/clear", clearColorStatsHandler)
	log.Fatal(http.ListenAndServe(":"+getServerPort(), nil))
}
