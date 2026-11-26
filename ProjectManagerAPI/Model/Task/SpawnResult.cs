using System.ComponentModel.DataAnnotations;

namespace ProjectManagerAPI.Model.Task
{
    public class SpawnResult
    {
        [Key]
        public int SpawnCount { get; set; }
    }
}
