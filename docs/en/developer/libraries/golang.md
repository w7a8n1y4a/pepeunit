# Golang

[Repository links](/en/development-pepeunit/maps#libraries)

::::info
This is a [Compilable](/en/definitions#compilable) client and it implements the full [Pepeunit Framework](/en/developer/libraries/framework) feature set.
::::

## Example

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	pepeunit "github.com/w7a8n1y4a/pepeunit_go_client"
)

// Basic PepeUnit Client Example

// To use this example, simply create a Pepeunit Unit based on the repository https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit on any instance.

// The resulting schema.json and env.json files should be added to the example directory.

// This example demonstrates basic usage of the PepeUnit client with both MQTT and REST functionality.
// It shows how to:
// - Initialize the client with configuration files
// - Set up message handlers
// - Subscribe to topics
// - Run the main application cycle
// - Storage api
// - Units Nodes api
// - Cipher api

// Global variable to track last message send time
var lastOutputSendTime time.Time
var inc int

func testSetGetStorage(client *pepeunit.PepeunitClient) {
	ctx := context.Background()
	if client.GetRESTClient() == nil {
		client.GetLogger().Warning("REST client not enabled, skip storage test")
		return
	}
	state := "This line is saved in Pepeunit Instance"
	if err := client.GetRESTClient().SetStateStorage(ctx, state); err != nil {
		client.GetLogger().Error(fmt.Sprintf("Test set state failed: %v", err))
		return
	}
	client.GetLogger().Info("Success set state")
	val, err := client.GetRESTClient().GetStateStorage(ctx)
	if err != nil {
		client.GetLogger().Error(fmt.Sprintf("Test get state failed: %v", err))
		return
	}
	client.GetLogger().Info(fmt.Sprintf("Success get state: %s", val))
}

func testGetUnits(client *pepeunit.PepeunitClient) {
	ctx := context.Background()
	if client.GetRESTClient() == nil {
		client.GetLogger().Warning("REST client not enabled, skip units query test")
		return
	}
	outputTopics := client.GetSchema().GetOutputTopic()
	topicURLs := outputTopics["output/pepeunit"]
	if len(topicURLs) == 0 {
		client.GetLogger().Warning("No output/pepeunit topics found in schema")
		return
	}
	topicURL := topicURLs[0]
	client.GetLogger().Info(fmt.Sprintf("Querying input unit nodes for topic: %s", topicURL))

	unitNodesResp, err := client.GetRESTClient().GetInputByOutput(ctx, topicURL, 100, 0)
	if err != nil {
		client.GetLogger().Warning(fmt.Sprintf("REST get_input_by_output failed: %v", err))
		return
	}
	count := 0
	if v, ok := unitNodesResp["count"].(float64); ok {
		count = int(v)
	}
	client.GetLogger().Info(fmt.Sprintf("Found %d unit nodes", count))

	unitNodeUUIDs := make([]string, 0)
	if arr, ok := unitNodesResp["unit_nodes"].([]interface{}); ok {
		for _, item := range arr {
			if m, ok := item.(map[string]interface{}); ok {
				if uuid, ok := m["uuid"].(string); ok && uuid != "" {
					unitNodeUUIDs = append(unitNodeUUIDs, uuid)
				}
			}
		}
	}
	if len(unitNodeUUIDs) == 0 {
		return
	}

	unitsResp, err := client.GetRESTClient().GetUnitsByNodes(ctx, unitNodeUUIDs, 100, 0)
	if err != nil {
		client.GetLogger().Warning(fmt.Sprintf("REST get_units_by_nodes failed: %v", err))
		return
	}
	unitCount := 0
	if v, ok := unitsResp["count"].(float64); ok {
		unitCount = int(v)
	}
	client.GetLogger().Info(fmt.Sprintf("Found %d units", unitCount))
	if arr, ok := unitsResp["units"].([]interface{}); ok {
		for _, item := range arr {
			if m, ok := item.(map[string]interface{}); ok {
				name, _ := m["name"].(string)
				uuid, _ := m["uuid"].(string)
				client.GetLogger().Info(fmt.Sprintf("Unit: %s (UUID: %s)", name, uuid))
			}
		}
	}
}

func testCipher(client *pepeunit.PepeunitClient) {
	key := client.GetSettings().PU_ENCRYPT_KEY
	if key == "" {
		client.GetLogger().Warning("PU_ENCRYPT_KEY is empty, skip cipher test")
		return
	}
	text := "pepeunit cipher test"
	enc, err := client.AESGCMEncode(text, key)
	if err != nil {
		client.GetLogger().Error(fmt.Sprintf("Cipher encode error: %v", err))
		return
	}
	client.GetLogger().Info(fmt.Sprintf("Cipher data %s", enc))
	dec, err := client.AESGCMDecode(enc, key)
	if err != nil {
		client.GetLogger().Error(fmt.Sprintf("Cipher decode error: %v", err))
		return
	}
	client.GetLogger().Info(fmt.Sprintf("Decoded data: %s", dec))
}

func handleInputMessages(client *pepeunit.PepeunitClient, msg pepeunit.MQTTMessage) {
	topicParts := strings.Split(msg.Topic, "/")

	// topic with format domain.com/+/pepeunit
	if len(topicParts) == 3 {
		// find topic name in schema, by topic with struct domain.com/+/pepeunit or domain.com/+
		topicName, err := client.GetSchema().FindTopicByUnitNode(
			msg.Topic, pepeunit.SearchTopicTypeFullName, pepeunit.SearchScopeInput,
		)

		if err != nil {
			client.GetLogger().Error(fmt.Sprintf("Error finding topic: %v", err))
			return
		}

		if topicName == "input/pepeunit" {
			value := string(msg.Payload)
			intValue, err := strconv.Atoi(value)
			if err != nil {
				client.GetLogger().Error(fmt.Sprintf("Value is not a number: %s", value))
				return
			}

			client.GetLogger().Debug(fmt.Sprintf("Get from input/pepeunit: %d", intValue), true)
		}
	}
}

func handleOutputMessages(client *pepeunit.PepeunitClient) {
	currentTime := time.Now()

	// Send data every DELAY_PUB_MSG from extras (fallback to PU_STATE_SEND_INTERVAL)
	delay, ok := client.GetSettings().GetInt("DELAY_PUB_MSG")
	if !ok || delay <= 0 {
		delay = client.GetSettings().PU_STATE_SEND_INTERVAL
	}
	if currentTime.Sub(lastOutputSendTime) >= time.Duration(delay)*time.Second {
		message := inc
		client.GetLogger().Debug(fmt.Sprintf("Send to output/pepeunit: %d", message), true)

		// Try to publish to sensor output topics
		ctx := context.Background()
		err := client.PublishToTopics(ctx, "output/pepeunit", strconv.Itoa(message))
		if err != nil {
			client.GetLogger().Error(fmt.Sprintf("Failed to publish message: %v", err))
		}

		// Update the last message send time
		lastOutputSendTime = currentTime
		inc++
	}
}

func main() {
	// Initialize the PepeUnit client
	client, err := pepeunit.NewPepeunitClient(pepeunit.PepeunitClientConfig{
		EnvFilePath:          "env.json",
		SchemaFilePath:       "schema.json",
		LogFilePath:          "log.json",
		EnableMQTT:           true,
		EnableREST:           true,
		CycleSpeed:           1 * time.Second, // 1 second cycle
		RestartMode:          pepeunit.RestartModeRestartExec,
		FFVersionCheckEnable: true,
		FFConsoleLogEnable:   true,
	})

	if err != nil {
		log.Fatalf("Failed to create PepeUnit client: %v", err)
	}

	// Test work pepeunit storage
	testSetGetStorage(client)

	// Test get edged units by output topic
	testGetUnits(client)

	// Test AES-GCM cipher
	testCipher(client)

	// Set up message handlers
	client.SetMQTTInputHandler(func(msg pepeunit.MQTTMessage) {
		handleInputMessages(client, msg)
	})

	// Connect to mqtt broker
	ctx := context.Background()
	err = client.GetMQTTClient().Connect(ctx)
	if err != nil {
		log.Fatalf("Failed to connect to MQTT broker: %v", err)
	}

	// Subscribe to all input topics from schema, be sure to after connecting with the broker
	err = client.SubscribeAllSchemaTopics(ctx)
	if err != nil {
		log.Fatalf("Failed to subscribe to topics: %v", err)
	}

	// Set up signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Create a cancellable context for the main cycle
	cycleCtx, cycleCancel := context.WithCancel(context.Background())

	// Run the main cycle with set output handler in a goroutine
	go func() {
		client.RunMainCycle(cycleCtx, handleOutputMessages)
	}()

	// Wait for shutdown signal
	<-sigChan
	client.GetLogger().Info("Shutting down...")

	// Stop the main cycle by canceling the context
	cycleCancel()

	// Disconnect from MQTT
	if client.GetMQTTClient() != nil {
		err = client.GetMQTTClient().Disconnect(ctx)
		if err != nil {
			client.GetLogger().Error(fmt.Sprintf("Failed to disconnect from MQTT: %v", err))
		}
	}

	client.GetLogger().Info("Shutdown complete")
}

```
