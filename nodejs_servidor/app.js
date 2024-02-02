const express = require("express");
const multer = require("multer");
const axios = require("axios");
const url = require("url");

const app = express();
const port = process.env.PORT || 3000;

const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

let cancelRequest = false;

app.use(express.static("public"));

app.use(express.json());

// Activar el servidor HTTP
const httpServer = app.listen(port, appListen);
async function appListen() {
  console.log(`Listening for HTTP queries on: http://127.0.0.1:${port}`);
}

// Tancar adequadament les connexions quan el servidor es tanqui
process.on("SIGTERM", shutDown);
process.on("SIGINT", shutDown);
function shutDown() {
  console.log("Received kill signal, shutting down gracefully");
  httpServer.close();
  process.exit(0);
}

app.get("/llistat", getLlistat);
async function getLlistat(req, res) {
  cancelRequest = true;
}

app.post("/data", upload.single("file"), async (req, res) => {
  console.log("Solicitud recibida correctamente.");
  const textPost = req.body;
  const uploadedFile = req.file;
  let objPost = {};

  try {
    objPost = JSON.parse(textPost.data);
  } catch (error) {
    res.status(400).send("Solicitud incorrecta.");
    console.log(error);
    return;
  }

  if (objPost.type === 'conversa') {
    console.log("Solicitud de tipo 'conversa' recibida correctamente.");
    if (uploadedFile) {
      const fileContent = uploadedFile.buffer.toString("utf-8");
      console.log(objPost.message)
      try {
        const axiosResponse = await axios.post(
          "http://127.0.0.1:11434/api/generate",
          fileContent,
          {
            responseType: "stream",
          }
        );

        res.writeHead(200, {
          "Content-Type": "application/json",
          "Transfer-Encoding": "chunked",
        });

        const responseStream = axiosResponse.data;

        processResponse(objPost.type, responseStream, res);
      } catch (error) {
        console.error("Error al realizar la solicitud:", error.message);
        res
          .status(500)
          .json({ error: "Error en la solicitud a la API externa" });
      }
    } else {
      res.status(400).send("Falta el archivo adjunto para el tipo 'conversa'.");
    }
  } else if (objPost.type === "imatge") {
    if (uploadedFile) {
      const fileContent = uploadedFile.buffer.toString("utf-8");

      try {
        const axiosResponse = await axios.post(
          "http://127.0.0.1:11434/api/generate",
          fileContent,
          {
            responseType: "stream",
          }
        );
        res.writeHead(200, {
          "Content-Type": "application/json",
          "Transfer-Encoding": "chunked",
        });

        const responseStream = axiosResponse.data;

        processResponse(objPost.type, responseStream, res);
      } catch (error) {
        console.error("Error al realizar la solicitud:", error.message);
        res
          .status(500)
          .json({ error: "Error en la solicitud a la API externa" });
      }
    } else {
      res.status(400).send("Falta el archivo adjunto para el tipo 'conversa'.");
    }
  } else {
    res.status(400).send("Tipo de solicitud no reconocido.");
  }
});

function processResponse(responseType, responseStream, res) {
  let partialResponse = "";
  responseStream.on("data", (chunk) => {
    if (cancelRequest) {
      // Si se ha solicitado la cancelación, detener el flujo de datos
      responseStream.destroy();
      res.end();
      cancelRequest = false;
      return;
    }

    const chunkString = chunk.toString();
    partialResponse += chunkString;
    const responseIndex = partialResponse.indexOf('"response":');
    if (responseIndex !== -1) {
      const responseSubstring = partialResponse.substring(responseIndex);
      const responseValue = JSON.parse(`{${responseSubstring}`).response;
      const modifiedJSON = { [responseType]: responseValue };
      res.write(JSON.stringify(modifiedJSON));
      partialResponse = "";
    }
  });

  responseStream.on("end", () => {
    res.end();
  });
}
