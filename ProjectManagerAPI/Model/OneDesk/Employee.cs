using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.OneDesk
{
    public class Employee
    {
        [Key]
        public int Enroll { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Designation { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public string SuperVisorName { get; set; } = string.Empty;
        public string OfficeEmail { get; set; } = string.Empty;
        public string ContactNo { get; set; } = string.Empty;
        public string JobStationName { get; set; } = string.Empty;
        public string BloodGroup { get; set; } = string.Empty;
        public string LatestCompanyName { get; set; } = string.Empty;
        public string LatestDesignation { get; set; } = string.Empty;
        public DateTime JoiningDate { get; set; } = DateTime.Now;
        public string PFileName { get; set; } = string.Empty;
        public byte[]? Photo { get; set; }= Array.Empty<byte>();
        public string Extension { get; set; } = string.Empty;
    }
}
