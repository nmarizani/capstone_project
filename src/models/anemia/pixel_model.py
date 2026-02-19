import tensorflow as tf
from tensorflow.keras.layers import Input, Dense, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam

def build_pixel_model(config):

    inp = Input(shape=(config["input_dim"],))
    x = inp

    for units in config["hidden_units"]:
        x = Dense(units, activation="relu")(x)
        x = BatchNormalization()(x)
        x = Dropout(config["dropout"])(x)

    embedding = Dense(config["embedding_dim"],
                      activation="relu",
                      name="embedding")(x)

    output = Dense(1, activation="sigmoid")(embedding)

    model = Model(inp, output)

    model.compile(
        optimizer=Adam(config["lr"]),
        loss="binary_crossentropy",
        metrics=[tf.keras.metrics.AUC(name="auc")]
    )

    return model