/**
 * @author Xin Wang
 * configuration for data handler
 */
public with sharing class GLBL_DataHandlerConfig {

	private List<ObjectConfig> objectConfigs = new List<ObjectConfig>();

	public class ObjectConfig{
		public String objName = null;
		public Integer priority = null;
		public Integer numOfObj = null;

		public ObjectConfig() {}
		public ObjectConfig(String objName, Integer priority, Integer howMany) {
			this.objName = objName;
			this.priority = priority;
			this.numOfObj = howMany;
		}
	}

	public GLBL_DataHandlerConfig() {}

	public virtual void addObject(String objName, Integer priority, Integer howMany) {
		this.objectConfigs.add(new ObjectConfig(objName, priority, howMany));
	}

	public List<ObjectConfig> getObjectConfigs() {
		return this.objectConfigs;
	}
}