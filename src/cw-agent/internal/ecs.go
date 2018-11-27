package internal

import (
	"bytes"
	"encoding/json"
	"net/http"
	"os"
)

// See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint-v2.html
const ecsTaskMetadataV2Endpoint = "http://169.254.170.2/v2/metadata"

type ecsTaskMetadata struct {
	TaskARN string
}

// GetTaskID gets the ECS task ID for the current container
func GetTaskID() (string, error) {
	if url := os.Getenv("ECS_CONTAINER_METADATA_URI"); url != "" {
		return getTaskIDv3(url)
	}
	if v := os.Getenv("ECS_TASK_ID"); v != "" {
		return v, nil
	}
	return getTaskIDv2()
}

func getTaskIDv3(url string) (string, error) {
	resp, err := http.Get(url + "/task")
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return "", err
	}
	metadata := ecsTaskMetadata{}
	if err := json.Unmarshal(buf.Bytes(), &metadata); err != nil {
		return "", err
	}

	return metadata.TaskARN, nil
}

func getTaskIDv2() (string, error) {
	resp, err := http.Get(ecsTaskMetadataV2Endpoint)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return "", err
	}
	metadata := ecsTaskMetadata{}
	if err := json.Unmarshal(buf.Bytes(), &metadata); err != nil {
		return "", err
	}

	return metadata.TaskARN, nil
}
