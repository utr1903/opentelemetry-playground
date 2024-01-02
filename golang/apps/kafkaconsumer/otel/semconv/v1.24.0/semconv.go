package semconv

import (
	"github.com/IBM/sarama"
	"go.opentelemetry.io/otel/attribute"
)

// GENERAL
// https://github.com/open-telemetry/semantic-conventions/tree/v1.24.0/docs/general
const (
	OtelStatusCodeName        = "otel.status_code"
	OtelStatusCode            = attribute.Key(OtelStatusCodeName)
	OtelStatusDescriptionName = "otel.status_description"
	OtelStatusDescription     = attribute.Key(OtelStatusDescriptionName)

	ExceptionEscapedName = "exception.escaped"
	ExceptionEscaped     = attribute.Key(ExceptionEscapedName)

	NetworkProtocolVersionName = "network.protocol.version"
	NetworkProtocolVersion     = attribute.Key(NetworkProtocolVersionName)
	UserAgentOriginalName      = "user_agent.original"
	UserAgentOriginal          = attribute.Key(UserAgentOriginalName)
	ServerAddressName          = "server.address"
	ServerAddress              = attribute.Key(ServerAddressName)
	ServerPortName             = "server.port"
	ServerPort                 = attribute.Key(ServerPortName)
	ClientAddressName          = "client.address"
	ClientAddress              = attribute.Key(ClientAddressName)
	ClientPortName             = "client.port"
	ClientPort                 = attribute.Key(ClientPortName)
)

// KAFKA
// https://github.com/open-telemetry/semantic-conventions/tree/v1.24.0/docs/messaging
const (
	KafkaConsumerName = "kafka_consumer"

	MessagingConsumerLatencyName = "messaging.receive.duration"

	MessagingSystemName          = "messaging.system"
	MessagingSystem              = attribute.Key(MessagingSystemName)
	MessagingOperationName       = "messaging.operation"
	MessagingOperation           = attribute.Key(MessagingOperationName)
	MessagingClientIdName        = "messaging.client_id"
	MessagingClientId            = attribute.Key(MessagingClientIdName)
	MessagingDestinationNameName = "messaging.destination.name"
	MessagingDestinationName     = attribute.Key(MessagingDestinationNameName)

	// KAFKA
	MessagingKafkaDestinationPartitionName = "messaging.kafka.destination.partition"
	MessagingKafkaDestinationPartition     = attribute.Key(MessagingKafkaDestinationPartitionName)
	MessagingKafkaConsumerGroupName        = "messaging.kafka.consumer.group"
	MessagingKafkaConsumerGroup            = attribute.Key(MessagingKafkaConsumerGroupName)
	MessagingKafkaMessageOffsetName        = "messaging.kafka.message.offset"
	MessagingKafkaMessageOffset            = attribute.Key(MessagingKafkaMessageOffsetName)
)

var (
	MessagingExplicitBucketBoundaries = []float64{
		0.005,
		0.010,
		0.025,
		0.050,
		0.075,
		0.100,
		0.250,
		0.500,
		0.750,
		1.000,
		2.500,
		5.000,
		7.500,
		10.000,
	}
)

func WithMessagingKafkaConsumerAttributes(
	msg *sarama.ConsumerMessage,
	consumerGroup string,
) []attribute.KeyValue {

	numAttributes := 4 // Operation, system, destination & partition

	// Create attributes array
	attrs := make([]attribute.KeyValue, 0, numAttributes)

	// Method, scheme & protocol version
	attrs = append(attrs, MessagingSystem.String("kafka"))
	attrs = append(attrs, MessagingOperation.String("receive"))
	attrs = append(attrs, MessagingDestinationName.String(msg.Topic))
	attrs = append(attrs, MessagingKafkaDestinationPartition.Int(int(msg.Partition)))
	attrs = append(attrs, MessagingKafkaConsumerGroup.String(consumerGroup))
	attrs = append(attrs, MessagingKafkaMessageOffset.Int(int(msg.Offset)))

	return attrs
}
