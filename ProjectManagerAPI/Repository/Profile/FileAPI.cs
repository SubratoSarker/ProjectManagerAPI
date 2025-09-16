using System.Net.Http.Headers;
using System.Text;
using Newtonsoft.Json;

namespace ProjectManagerAPI.Repository.Profile
{
    public class FileAPI
    {
        private static readonly HttpClient _client = new HttpClient();

        protected static readonly string ApiDeviceDetails = "erp";
        protected static readonly string ApiChannel = "web";
        protected static readonly string ApiUserId = "erp";
        protected static readonly string ApiPassword = "!erp@98766789";
        protected static readonly string ApiBaseUrl = "https://fileuploaddownloadapi.akijbashir.com/api";

        private async Task<string?> GetTokenAsync()
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
    }
}
