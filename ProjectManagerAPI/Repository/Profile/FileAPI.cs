using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Newtonsoft.Json;

namespace ProjectManagerAPI.Repository.Profile
{
    public class FileAPI
    {
        private static readonly HttpClient _client = new HttpClient();
        private static readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };

        protected static readonly string ApiDeviceDetails = "erp";
        protected static readonly string ApiChannel = "web";
        protected static readonly string ApiUserId = "erp";
        protected static readonly string ApiPassword = "!erp@98766789";
        protected static readonly string ApiBaseUrl = "https://fileuploaddownloadapi.akijbashir.com/api";

        public static string TaskAttachmentFolder(int taskId) => $"PROJECTMANAGEMENT/{taskId}/Attachments";

        public async Task<string?> GetTokenAsync()
        {
            string url = $"{ApiBaseUrl}/Login/Login";
            var requestBody = new
            {
                userid = ApiUserId,
                password = ApiPassword,
                devicedetails = ApiDeviceDetails,
                channel = ApiChannel
            };

            var content = new StringContent(JsonConvert.SerializeObject(requestBody), Encoding.UTF8, "application/json");

            try
            {
                var response = await _client.PostAsync(url, content);
                if (response.IsSuccessStatusCode)
                {
                    var responseBody = await response.Content.ReadAsStringAsync();
                    dynamic responseJson = JsonConvert.DeserializeObject(responseBody);
                    return responseJson?.token;
                }
            }
            catch (Exception ex)
            {
                // log ex.Message
            }

            return null;
        }

        public async Task<(byte[]? Photo, string FileName)> GetSingleFileFromBase64Async(string Enroll)
        {
            string fileName = string.Empty;
            byte[]? photoBytes = null;

            string url = $"{ApiBaseUrl}/FileUploadDownload/DownloadSingleFileAsBase64?userid={ApiUserId}&password={ApiPassword}&userFolder=EMPLOYEEUPDATE/{Enroll}/Profile";
            string? token = await GetTokenAsync();

            if (!string.IsNullOrEmpty(token))
            {
                var request = new HttpRequestMessage(HttpMethod.Get, url);
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
                var response = await _client.SendAsync(request);

                if (response.IsSuccessStatusCode)
                {
                    string responseBody = await response.Content.ReadAsStringAsync();
                    dynamic responseJson = Newtonsoft.Json.JsonConvert.DeserializeObject(responseBody);

                    if (responseJson?.base64FileResponse != null && responseJson.base64FileResponse.Count > 0)
                    {
                        string base64Content = responseJson.base64FileResponse[0].base64Content;
                        fileName = responseJson.base64FileResponse[0].fileName;

                        if (!string.IsNullOrEmpty(base64Content))
                            photoBytes = Convert.FromBase64String(base64Content);
                    }
                }
            }

            return (photoBytes, fileName);
        }

        public async Task<(bool Success, string Message)> UploadSingleFileAsync(string folder, Stream fileStream, string fileName, string contentType)
        {
            string? token = await GetTokenAsync();
            if (string.IsNullOrEmpty(token))
            {
                return (false, "Could not authenticate with the file upload service.");
            }

            try
            {
                using var content = new MultipartFormDataContent();
                using var fileContent = new StreamContent(fileStream);
                fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse(string.IsNullOrEmpty(contentType) ? "application/octet-stream" : contentType);
                content.Add(fileContent, "formFile", fileName);

                string url = $"{ApiBaseUrl}/FileUploadDownload/UploadSingleFile?userFolder={Uri.EscapeDataString(folder)}&userid={ApiUserId}&password={ApiPassword}";
                using var request = new HttpRequestMessage(HttpMethod.Post, url) { Content = content };
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var response = await _client.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    return (false, $"Upload failed with status {(int)response.StatusCode}.");
                }

                var result = await response.Content.ReadFromJsonAsync<UploadResult>(_jsonOptions);
                if (result is null || !result.Status)
                {
                    return (false, result?.Message ?? "Unknown upload error.");
                }
                return (true, "Uploaded Successfully.");
            }
            catch (Exception ex)
            {
                return (false, ex.Message);
            }
        }

        public async Task<(byte[]? Content, string? FileName)> GetFileFromFolderAsync(string folder, string fileName)
        {
            string? token = await GetTokenAsync();
            if (string.IsNullOrEmpty(token))
            {
                return (null, null);
            }

            string url = $"{ApiBaseUrl}/FileUploadDownload/DownloadMultipleFileAsBase64?userid={ApiUserId}&password={ApiPassword}&userFolder={Uri.EscapeDataString(folder)}";
            var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            var response = await _client.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                return (null, null);
            }

            string responseBody = await response.Content.ReadAsStringAsync();
            dynamic? responseJson = JsonConvert.DeserializeObject(responseBody);
            if (responseJson?.base64FileResponse == null)
            {
                return (null, null);
            }

            foreach (var file in responseJson.base64FileResponse)
            {
                string entryName = file.fileName;
                if (string.Equals(entryName, fileName, StringComparison.OrdinalIgnoreCase))
                {
                    string base64Content = file.base64Content;
                    return (string.IsNullOrEmpty(base64Content) ? null : Convert.FromBase64String(base64Content), entryName);
                }
            }
            return (null, null);
        }

        private sealed class UploadResult
        {
            public bool Status { get; set; }
            public string? Message { get; set; }
        }
    }
}
