/**
 * @author Xin Wang <xwang4@deloitte.ie>
 * tool for setting up dummy data for project
 *
 * if you need to modify any functions, please, make sure that he functions
 * are tested thoroughly.
 */
public with sharing class GLBL_DataHandler 
	implements 
		Database.Batchable<sObject>,
		Database.AllowsCallouts,
		Database.Stateful{

	// statics members
	public static string namespace = '';
	public static string classname = 'GLBL_DataHandler';

	// non-static members
	public String emailSuffix = '';
	public String action = '';
	public String query = '';
	public Integer batchSize = 2000;
	public List<sObject> objToProcess = new List<sObject>();
	public List<String> objects = new List<String>();
	public Map<String, objectDetail> od = new Map<String, objectDetail>();

	public class GLBL_DataHandlerException extends Exception {}

	static {
		// @todo
		// naming convention for partial batch recognition will be 
		// implemented for different cases
		namespace = UserInfo.getOrganizationId() + '-' + classname;
	}

	// constructor
	public GLBL_DataHandler() {
		this.emailSuffix = 'novartis.com';
	}

	// constructor override
	public GLBL_DataHandler(GLBL_DataHandlerConfig dhc) {
		this();
		this.init(dhc);
	}

	public void init(GLBL_DataHandlerConfig dhc) {
		if(dhc != null) {
			List<GLBL_DataHandlerConfig.ObjectConfig> tt = dhc.getObjectConfigs();
		}
	}

	/**
	 * responsible for generating the close-to-real data
	 */
	public class Dictionary {
		public List<String> cache = new List<String>();
		public List<String> firstNames = new List<String>();
		public List<String> lastNames = new List<String> ();
		public String genFullName () {
			return 'full name';
		}
		public String genEmail() {
			return 'email';
		}
		public String genId() {
			return 'id';
		}
		public String genAddress() {
			return 'address';
		}
		public void genDate(Date startDate, Date endDate, Boolean isInclusive) {
		}
	}

	public class FieldDetail {
		public String name = '';
		public String fieldValueType = '';
		public String fieldType = '';
		public Boolean isNillable = false;
		public String label = '';
		public Boolean isCustom = false;
		public String objectType = 'Custom';
		public Boolean isUnique = false;
		public Boolean isChild = false;
		public String referenceTo = '';

		public FieldDetail(Schema.DescribeFieldResult f) {
			this.name = f.getName(); 
			this.fieldValueType = String.valueOf(f.getType()); 
			this.isNillable = f.isNillable();
			this.label = f.getLabel();
			this.isCustom = f.isCustom();
			this.fieldType = this.isCustom ? 'Custom' : 'Standard';
			this.isUnique = f.isUnique();
			this.isChild = f.getRelationshipOrder() == 1;
			List<Schema.sObjectType> hello = f.getReferenceTo();
			if(hello != null && hello.size() > 0) {
				this.referenceTo = hello[0].getDescribe().getName();
			}
		}
	}

	public class ObjectDetail{
		public String name = '';
		public Integer total = 0;
		public Boolean isRequired = false;
		public Boolean directlyRequired = false;
		public Integer requiredTotal = 0;
		public Integer referencedTotal = 0;
		public List<FieldDetail> fieldDetails = new List<FieldDetail>();
		public ObjectDetail(String name) {
			this.name = name;
		}
		public void addFieldDetail(FieldDetail fd) {
			this.fieldDetails.add(fd);
		}
	}

	@remoteAction
	public static List<sObject> query (String objName, String match) {
		String q = 'SELECT id, name from ' + objName + ' where name like \'%'+ match +'%\' limit 10';
		List<sObject> so = Database.query(q);
		return so;
	}

	/**
	 * get all objs from the org and assemble info into 
	 * @param {}
	 */
	@remoteAction
	public static List<ObjectDetail> getAllObjects() {
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		List<ObjectDetail> ods = new List<ObjectDetail>();
		ObjectDetail od;
		Schema.DescribeSObjectResult[] descResult = null;
		for(String k: gd.keyset()) {
			descResult = Schema.describeSObjects(new String[]{k});
			if(descResult[0].isCustom()) {
				od = new ObjectDetail(k);
				Map<String, Schema.SObjectField> fields = descResult[0].fields.getMap();
				for(String kk: fields.keyset()) {
					od.addFieldDetail(genFieldDetail(fields.get(kk).getDescribe()));
				}
				ods.add(od);
			}
		}
		return ods;
	}

	@remoteAction
	public static List<ObjectDetail> genRecords(List<ObjectDetail> info) {
		GLBL_DataHandler gd = new GLBL_DataHandler();
		//gd.setObjectList(info);
		//gd.sortObjectList(info);
		//Database.executeBatch(gd);
		return info;
	}

	private static FieldDetail genFieldDetail(Schema.DescribeFieldResult f) {
		return new FieldDetail(f);
	}

	/**
	 *  create sobject based a string type
	 * @param {String} typeInStr
	 */
	public static sObject createObjectByTypeInString(String typeInStr) {
		Schema.SObjectType convertType = Schema.getGlobalDescribe().get(typeInStr);
		Sobject obj = convertType.newSObject();
		// obj.put(fieldname, value); @do this to put value to sobject
		return obj;
	}

	/**
	 * @implement Database.batchable
	 */
   	public Iterable<sObject> start(Database.BatchableContext BC) {
   		if(this.action == 'delete') {
   			this.query = 'Select id from ' + 'currentobjectname limit ' + this.batchSize;
   			List<sObject> obj = Database.query(this.query);
   			return obj;
   		}
   		else if(this.action == 'insert') {
   			List<sObject> obj = this.getSObjectReady(2000);
   		}
   		return this.objToProcess;
   	}

   	public virtual void trackCurrentObjProcessStatus() {
   		// 1. which object am i processing
   		// 2. where am i on this object
   	}

   	/**
   	 * mock creating records
   	 * @param {}
   	 */
   	public virtual List<User> getSObjectReady(Integer num) {
   		if(num > this.batchSize) {
   			throw new GLBL_DataHandlerException('size exceeded you batch allowence.');
   		}
   		List<User> us = new List<User>();
   		for(Integer i = 0; i < num ;i ++) {
   			us.add(new User());
   		}
   		return us;
   	}

   	/**
   	 * @implements batchable
   	 */
   	public void execute(Database.BatchableContext BC, List<sObject> scope){
		this.onExecute(BC, scope, this.action);
	}

	public virtual void onExecute(Database.BatchableContext BC, List<sObject> scope, String action) {
		// this is what you do when execute is in action
	}

	/**
	 * @implements batchable
	 */
   	public void finish(Database.BatchableContext BC){
   		// track current object process status
   		// upadate current query and sobject
   	}

}