<?php

if($_SERVER['REQUEST_METHOD'] === 'POST')
{
    $base64Image = $_POST['base64Image'];
    $type        = $_POST['type'];
    $token       = $_POST['token'];
    $id          = intval($_POST['id']);

    if(empty($base64Image))
    {
        $response = ['error' => 'Nenhuma imagem recebida'];
        echo json_encode($response);
        exit();
    }
    else
    {
        $dbHost = '177.44.248.73';
        $dbName = 'petaffection';
        $dbUser = 'petaffection';
        $dbPass = 'petaffection';
        
        $conn = new PDO("pgsql:host=$dbHost;dbname=$dbName", $dbUser, $dbPass);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Consulta ao banco para verificar o token
        $stmt = $conn->prepare('SELECT token FROM cad_person WHERE id = :id');
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $storedToken = $row['token'];

        if($storedToken === $token)
        {
            $imageData = base64_decode($base64Image);
            $filename = uniqid() . '.jpg';
            $tmpPath = "/var/www/html/repository/";
            
            $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

            if($ext !== 'jpeg' && $ext !== 'jpg' && $ext !== 'png')
            {
                $response = ['error' => 'Erro: Extensão de arquivo inválida. Apenas JPEG, JPG e PNG são permitidos'];
                echo json_encode($response);
                exit();
            }

            file_put_contents($tmpPath . $filename, $imageData);
            $filePath = $tmpPath . $filename;

            if(file_exists($filePath))
            {
                if($type === 'imagePerson')
                {
                    echo $filePath;
                }
                elseif($type === 'imageMyPet')
                {
                    echo $filePath;
                }
                elseif($type === 'lostPet')
                {
                    echo $filePath;
                }
                elseif($type == 'findMyPet')
                {
                    echo $filePath;
                }
                else
                {
                    $response = ['error' => 'Tipo não definido'];
                    echo json_encode($response);
                    exit();
                }
            }
            else
            {
                $response = ['error' => 'Arquivo Inválido'];
                echo json_encode($response);
                exit();
            }
        }
        else
        {
            $response = ['error' => 'Token inválido'];
            echo json_encode($response);
            exit();
        }
    }
}
else
{
    $response = ['error' => 'Método inválido'];
    echo json_encode($response);
    exit();
}
