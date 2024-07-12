using ProjectManagementAPI.Model.Security;

namespace ProjectManagerAPI.Repository.Security
{
    public interface IAPIValidation
    {
        public APIValidationResponse apiValidation(APIValidationRequest APIValidationRequest);
    }
}
